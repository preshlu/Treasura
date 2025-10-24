# Dividend Payout System Smart Contract

## Overview
A Clarity smart contract for managing dividend distributions to verified shareholders with controlled payout windows and comprehensive investor verification.

## Features
- **Investor Accreditation**: Controller-managed accredited investor list
- **Share Certificate Management**: Track and verify share certificate issuance
- **Dividend Allocation**: Set individual or mass dividend allocations
- **Controlled Withdrawals**: Toggle payout windows with verification checks
- **Withdrawal Tracking**: Prevent duplicate withdrawals
- **Mass Distribution**: Batch process up to 200 investor payouts

## Constants
- `treasury-controller`: Contract deployer, has administrative privileges
- `total-dividend-pool`: Initial pool of 5,000,000 units

## Error Codes
- `u100`: Controller-only operation
- `u101`: Dividend already withdrawn
- `u102`: Not a verified shareholder
- `u103`: No dividend allocation found
- `u104`: Payout window suspended
- `u105`: Invalid investor address
- `u106`: Invalid payout amount

## Public Functions

### Administrative Functions (Controller Only)

#### `accredit-investor`
```clarity
(accredit-investor (investor principal))
```
Adds an investor to the accredited investor list.

#### `remove-accreditation`
```clarity
(remove-accreditation (investor principal))
```
Removes an investor from the accredited investor list.

#### `issue-certificate`
```clarity
(issue-certificate (investor principal) (has-shares bool))
```
Issues or revokes share certificates for investors.

#### `set-dividend-allocation`
```clarity
(set-dividend-allocation (investor principal) (payout uint))
```
Allocates dividend amount to a specific investor. Amount must be greater than 0 and within the total dividend pool.

#### `mass-dividend-distribution`
```clarity
(mass-dividend-distribution (investors (list 200 principal)) (payouts (list 200 uint)))
```
Batch sets dividend allocations for multiple investors. Lists must be equal length (max 200).

#### `toggle-payout`
```clarity
(toggle-payout)
```
Opens or closes the dividend withdrawal window.

### Investor Functions

#### `withdraw-dividend`
```clarity
(withdraw-dividend)
```
Allows verified shareholders to withdraw their allocated dividends when the payout window is active.

**Requirements:**
- Payout window must be active
- Investor must be accredited
- Investor must have a valid share certificate
- Investor must have a dividend allocation
- Investor must not have already withdrawn

## Read-Only Functions

#### `get-dividend-allocation`
Returns the dividend amount allocated to an investor.

#### `has-withdrawn`
Checks if an investor has already withdrawn their dividend.

#### `verify-shareholder`
Verifies if an investor is both accredited and has a share certificate.

#### `is-payout-active`
Returns the current status of the payout window.

#### `get-dividend-pool`
Returns the total dividend pool amount.

#### `get-investor-details`
Returns comprehensive investor information including:
- Dividend allocation
- Withdrawal status
- Shareholder verification
- Accreditation status
- Certificate status
- Withdrawal eligibility

## Workflow

1. **Setup Phase** (Controller):
   - Accredit investors using `accredit-investor`
   - Issue share certificates using `issue-certificate`
   - Set dividend allocations using `set-dividend-allocation` or `mass-dividend-distribution`

2. **Distribution Phase** (Controller):
   - Open payout window using `toggle-payout`

3. **Withdrawal Phase** (Investors):
   - Eligible investors call `withdraw-dividend` to claim their dividends

4. **Close Phase** (Controller):
   - Close payout window using `toggle-payout`

## Security Features
- Only treasury controller can modify investor records and dividend allocations
- Double-withdrawal prevention through withdrawal records
- Multi-factor investor verification (accreditation + certificate)
- Payout window controls for time-bound distributions
- Input validation for all investor addresses and payout amounts
