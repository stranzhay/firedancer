# Security

The following document describes various aspects of the Firedancer security program.

## Table of Contents

- [3rd Party Security Audits](#3rd-Party-Security-Audits)
- [Bug Bounty Program](#Bug-Bounty-Program)


## 3rd Party Security Audits

The Firedancer project engages 3rd party firms to conduct independent security audits of Firedancer.

As these 3rd party audits are completed and issues are sufficiently addressed, we make those audit reports public.

- Q4 2022 - Runtime Verification (testing)

## Bug Bounty Program

Jump Crypto operates the Firedancer bug bounty program to financially incentivize independent researchers to find and responsibly disclose security issues.
Either a demonstration or a valid bug report is all that's necessary to submit a bug bounty.
A patch to fix the issue isn't required.

**Do not use GitHub issues to report vulnerabilities.**

Please create [a new Security Advisory](https://github.com/firedancer-io/firedancer/security/advisories/new) so that we can collaborate together.

### Payout
Valid reports are paid out in **SOL tokens** locked for 12 months.

### Platform eligibility
Bugs will only be considered valid if they are effective against a Firedancer validator configured as recommended and deployed on an officially supported platform. For the time being, the only supported platform is Linux on an x86_64 processor.

### Tier 1
#### Payout
| Stage           | Payout        |
| -----           | -----         |
| Mainnet         | 2,000,000 USD |
| Testnet + 2 mo. | 600,000 USD   |

#### Scope
* Compromise of the validator host system e.g. spawning another arbitrary process
* Gaining access to confidential information e.g. validator private keys, secrets in envvars, shadow file, etc.
* Theft of funds that would normally require a signature

### Tier 2
#### Payout
| Stage           | Payout        |
| -----           | -----         |
| Mainnet         | 500,000 USD   |
| Testnet + 2 mo. | 150,000 USD   |

#### Scope
* Denial of Service, not due to line saturation, resulting in an extended network outage
* Cryptographic implementation flaws and flaws in random number generation with limited impact.
* Consensus safety violation
* Tricking a validator to accept an optimistic confirmation or rooted slot without a double vote, etc.

### Tier 3
#### Payout
| Stage           | Payout        |
| -----           | -----         |
| Mainnet         | 250,000 USD   |
| Testnet + 2 mo. | 75,000 USD    |

#### Scope
* Denial of Service, not due to line saturation, resulting in a degradation of performance impacting non-RPC endpoints
* Non-social attacks against source code change management, automated testing, release build, release publication and release hosting infrastructure of the monorepo

### Tier 4
#### Payout
| Stage           | Payout        |
| -----           | -----         |
| Mainnet         | 5,000 USD     |
| Testnet + 2 mo. | 1,500 USD     |

#### Scope
* Denial of Service of RPC endpoint

> **_NOTE:_** Testnet + 2mo. means that the targeted release must have been approved for testnet usage for at least two months.

> **_NOTE:_** If you found a bug that is exploitable only when the sandbox is (partially or fully) disabled, you are eligible for 5% of the bounty. For example, if you are able to "pop a calc" but needed to disable the sandbox to achieve it, you would be eligible for a $100,000 USD bounty.

### Out-of-scope
* Attacks that the have already been exploited
* Denial of service due to volume
* Reports regarding bugs that the Wormhole project was previously aware of are not eligible for a reward

### Prohibited activities
* The following person(s) are ineligible to receive bug bounty payout rewards: Staff, Auditors, Contractors, persons in possession of privileged information, and all associated parties
* Any testing with mainnet or public testnets; all testing should be done on private nets
* Public disclosure of a vulnerability before an embargo has been lifted
* Any testing with third party smart contracts or infrastructure and websites
* Attempting phishing or other social engineering attacks against our employees and/or customers
* Any denial of service attacks
* Violating the privacy of any organization or individual
* Automated testing of services that generates significant amounts of traffic
* Any activity that violates any law or disrupts or compromises any data or property that is not your own

### Submission requirements and conditions
All reports must come with sufficient explanation and data to easily reproduce the bug, e.g. through a proof-of-concept code.

All rewards are decided on a case-by-case basis, taking into account the exploitability of the bug, the impact it causes, and the likelihood of the vulnerability presenting itself if it is non-deterministic or some of the conditions are not present at the time. The rewards presented in the payout structure above are the maximum rewards and there are no minimum rewards.

In cases where the report achieves more than one of the above objectives, rewards will be tiered to the higher of the two objectives and will not be aggregated.

Rewards for bugs in dependencies and third party code are at the discretion of the Firedancer team and will be based on the impact demonstrated on Firedancer. If the dependency has its own bug bounty program, your reward for submitting this vulnerability to Firedancer will be lowered by the expected payout of that other program.

If there is a duplicate report, either the same reporter or different reporters, the first of the two by timestamp will be accepted as the official bug report and will be subject to the specific terms of the submitting program.


### Bounty eligibility
The Firedancer team will maintain full discretion on the payouts for vulnerabilities. We do encourage bug reporters to submit issues outside of the above-mentioned payout structure, though we want to be clear that we’ll exercise discretion on a case-by-case basis -- whether an issue warrants a payout and what that ultimate payout would be.

Additionally, for a bug report to be paid, we do require the bug reporter to comply with our [KYC](https://en.wikipedia.org/wiki/Know_your_customer) requirements.
This includes the following:

* Wallet address where you’ll receive payment
* Proof of address (either a redacted bank statement with your address or a recent utility bill with your name, address, and issuer of the bill)
* If you are a U.S. person, please send us a filled-out and signed [W-9](https://www.irs.gov/pub/irs-pdf/fw9.pdf)
* If you are not a U.S. person, please send us a filled-out and signed [W-8BEN](https://www.irs.gov/pub/irs-pdf/fw8ben.pdf)
* Copy of your passport will be required.

These details will only be required upon determining that a bug report will be rewarded and they will remain strictly confidential within need-to-know individuals (basically, only individuals required to verify KYC and process the payment).
