## Auth and IAP

|  | new google / new apple / email | existing google / apple / email |
| --- | --- | --- |
| no anon, sign in |  pass / pass / pass | pass / pass / pass |
| no anon, sign up | pass / pass / pass | pass / pass / pass |
| yes anon, sign in | pass / pass / n/a |  |
| yes anon, sign up | pass / pass / pass | pass /  |

Other scenarios:

- new claim matches claim from other identity: pass (auto links)
- already logged in → iap
- household shares entitlements
- restore purchase
