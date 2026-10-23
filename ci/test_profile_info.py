import copy
import datetime
import unittest
from profile_info import validate


class ProfileValidationTests(unittest.TestCase):
    def setUp(self):
        self.now = datetime.datetime(2026, 10, 23, tzinfo=datetime.timezone.utc)
        self.profile = {
            'UUID': 'AABBCCDD-1234-1234-1234-123456789ABC',
            'TeamIdentifier': ['ABCD123456'],
            'ApplicationIdentifierPrefix': ['ABCD123456'],
            'Platform': ['iOS'],
            'ExpirationDate': datetime.datetime(2027, 1, 1),
            'DeveloperCertificates': [b'synthetic-test-certificate'],
            'Entitlements': {
                'application-identifier': 'ABCD123456.com.cihanemre.SheepCrate3D',
                'com.apple.developer.team-identifier': 'ABCD123456',
                'get-task-allow': False,
            },
        }

    def check(self, profile):
        return validate(profile, 'ABCD123456', 'com.cihanemre.SheepCrate3D', self.now)

    def test_valid_profile_and_certificate_fingerprint(self):
        uuid, fingerprint = self.check(self.profile)
        self.assertEqual(uuid, self.profile['UUID'])
        self.assertRegex(fingerprint, r'^[A-F0-9]{40}$')

    def test_reject_other_team(self):
        self.profile['TeamIdentifier'] = ['OTHER12345']
        with self.assertRaises(ValueError): self.check(self.profile)

    def test_reject_wildcard_or_other_app(self):
        for app in ['ABCD123456.*', 'ABCD123456.com.other.app']:
            with self.subTest(app=app):
                self.profile['Entitlements']['application-identifier'] = app
                with self.assertRaises(ValueError): self.check(self.profile)

    def test_reject_development_adhoc_enterprise(self):
        for change in [
            {'ProvisionedDevices': ['device']},
            {'ProvisionsAllDevices': True},
            {'Entitlements': dict(self.profile['Entitlements'], **{'get-task-allow': True})},
        ]:
            with self.subTest(change=change):
                profile = copy.deepcopy(self.profile); profile.update(change)
                with self.assertRaises(ValueError): self.check(profile)

    def test_reject_expired_profile(self):
        self.profile['ExpirationDate'] = self.now - datetime.timedelta(seconds=1)
        with self.assertRaises(ValueError): self.check(self.profile)

    def test_reject_invalid_uuid_or_missing_certificate(self):
        for change in [{'UUID': '../../unexpected'}, {'DeveloperCertificates': []}]:
            profile = copy.deepcopy(self.profile); profile.update(change)
            with self.assertRaises(ValueError): self.check(profile)


if __name__ == '__main__': unittest.main()
