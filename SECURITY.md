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

Please create (a new Security Advisory)(https://github.com/firedancer-io/firedancer/security/advisories/new) so that we can collaborate together.

### Mainnet bounties
Mainnet bounties are only applicable to vulnerabilities exploitable due to components/features which the Firedancer Team approved for Mainnet usage.

Todo: Determine the best way to communicate mainnet readiness of components.

#### Loss of Funds:
$2,000,000 USD in locked SOL tokens (locked for 12 months)
* Theft of funds without users signature from any account
* Theft of funds without users interaction in system, token, stake, vote programs
* Theft of funds that requires users signature - creating a vote program that drains the delegated stakes.

#### Consensus/Safety Violations:
$1,000,000 USD in locked SOL tokens (locked for 12 months)
* Consensus safety violation
* Tricking a validator to accept an optimistic confirmation or rooted slot without a double vote, etc.

#### Liveness / Loss of Availability:
$400,000 USD in locked SOL tokens (locked for 12 months)
* Whereby consensus halts and requires human intervention
* Eclipse attacks,
* Remote attacks that partition the network,

#### DoS Attacks:
$100,000 USD in locked SOL tokens (locked for 12 months)
* Remote resource exaustion via Non-RPC protocols

#### Supply Chain Attacks:
$100,000 USD in locked SOL tokens (locked for 12 months)
* Non-social attacks against source code change management, automated testing, release build, release publication and release hosting infrastructure of the monorepo.

#### RPC DoS/Crashes:
$5,000 USD in locked SOL tokens (locked for 12 months)
* RPC attacks


### Testnet bounties
Mainnet bounties are only applicable to vulnerabilities exploitable due to components/features which the Firedancer Team approved for Testnet usage for **at least three months**.

#### Loss of Funds:
$1,000,000 USD in locked SOL tokens (locked for 12 months)
* Theft of funds without users signature from any account
* Theft of funds without users interaction in system, token, stake, vote programs
* Theft of funds that requires users signature - creating a vote program that drains the delegated stakes.

#### Consensus/Safety Violations:
$500,000 USD in locked SOL tokens (locked for 12 months)
* Consensus safety violation
* Tricking a validator to accept an optimistic confirmation or rooted slot without a double vote, etc.

#### Liveness / Loss of Availability:
$200,000 USD in locked SOL tokens (locked for 12 months)
* Whereby consensus halts and requires human intervention
* Eclipse attacks,
* Remote attacks that partition the network,

#### DoS Attacks:
$50,000 USD in locked SOL tokens (locked for 12 months)
* Remote resource exaustion via Non-RPC protocols

#### Supply Chain Attacks:
$50,000 USD in locked SOL tokens (locked for 12 months)
* Non-social attacks against source code change management, automated testing, release build, release publication and release hosting infrastructure of the monorepo.

#### RPC DoS/Crashes:
$2,500 USD in locked SOL tokens (locked for 12 months)
* RPC attacks


If you find a security issue in Firedancer, please report the issue immediately using [this form](https://jumpcrypto.com/firedancer/bounty/).

If there is a duplicate report, either the same reporter or different reporters, the first of the two by timestamp will be accepted as the official bug report and will be subject to the specific terms of the submitting program.



