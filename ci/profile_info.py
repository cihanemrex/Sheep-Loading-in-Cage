"""Validate one App Store distribution profile and prepare export settings."""
import datetime
import hashlib
import os
from pathlib import Path
import plistlib
import re
import sys


def validate(profile, team, bundle, now=None):
    if not re.fullmatch(r'[A-Z0-9]{10}', team):
        raise ValueError('APPLE_TEAM_ID must be the 10-character Apple Team ID.')
    if not re.fullmatch(r'[A-Za-z0-9.-]+', bundle):
        raise ValueError('Invalid APP_BUNDLE_ID.')
    if team not in profile.get('TeamIdentifier', []):
        raise ValueError('Provisioning profile belongs to a different Apple team.')
    entitlements = profile.get('Entitlements', {})
    app_id = entitlements.get('application-identifier', '')
    prefixes = profile.get('ApplicationIdentifierPrefix', [team])
    if app_id not in [prefix + '.' + bundle for prefix in prefixes]:
        raise ValueError('Profile App ID must exactly match ' + bundle)
    if entitlements.get('com.apple.developer.team-identifier') != team:
        raise ValueError('Profile entitlement team does not match APPLE_TEAM_ID.')
    if entitlements.get('get-task-allow', False) or 'ProvisionedDevices' in profile or profile.get('ProvisionsAllDevices'):
        raise ValueError('Use an App Store Connect distribution profile, not Development, Ad Hoc or Enterprise.')
    if 'iOS' not in profile.get('Platform', []):
        raise ValueError('Profile is not for iOS.')
    expiration = profile.get('ExpirationDate')
    if not isinstance(expiration, datetime.datetime):
        raise ValueError('Profile has no expiration date.')
    if expiration.tzinfo is None:
        expiration = expiration.replace(tzinfo=datetime.timezone.utc)
    if expiration <= (now or datetime.datetime.now(datetime.timezone.utc)):
        raise ValueError('Provisioning profile has expired.')
    uuid = profile.get('UUID', '')
    if not re.fullmatch(r'[A-Fa-f0-9-]{36}', uuid):
        raise ValueError('Invalid profile UUID.')
    certificates = profile.get('DeveloperCertificates', [])
    if len(certificates) != 1:
        raise ValueError('Expected one distribution certificate in profile.')
    return uuid, hashlib.sha1(certificates[0]).hexdigest().upper()


def main():
    directory = Path(sys.argv[1])
    profile = plistlib.loads((directory / 'profile.plist').read_bytes())
    team, bundle = os.environ['APPLE_TEAM_ID'], os.environ['APP_BUNDLE_ID']
    uuid, fingerprint = validate(profile, team, bundle)
    export = {
        'method': 'app-store-connect', 'destination': 'export',
        'teamID': team, 'signingStyle': 'manual',
        'signingCertificate': fingerprint,
        'provisioningProfiles': {bundle: uuid},
        'manageAppVersionAndBuildNumber': False,
        'uploadSymbols': True,
    }
    (directory / 'ExportOptions.plist').write_bytes(plistlib.dumps(export))
    for name, value in [('PROFILE_UUID', uuid), ('SIGNING_IDENTITY', fingerprint)]:
        with open(os.environ['GITHUB_ENV'], 'a') as env:
            env.write(name + '=' + value + '\n')


if __name__ == '__main__':
    try:
        main()
    except (ValueError, KeyError, OSError, plistlib.InvalidFileException) as error:
        raise SystemExit('Profile validation failed: ' + str(error))
