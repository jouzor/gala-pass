# Gala Pass - Fundraising Event Tickets Smart Contract

A transparent, blockchain-based ticketing system for fundraising events built on the Stacks blockchain using Clarity smart contracts.

## Overview

Gala Pass enables organizations to host fundraising events with complete transparency, automatic tax receipt generation, and verifiable impact reporting. All donations are tracked on-chain, ensuring accountability and trust between organizers and donors.

## Features

### 🎫 Event Management
- Create and manage fundraising events
- Set ticket prices and capacity limits
- Define event causes and descriptions
- Activate/deactivate events as needed

### 💰 Transparent Donation Tracking
- Real-time tracking of all donations
- Public visibility of funds raised
- Immutable record of all transactions
- Per-event donation statistics

### 📄 Automatic Tax Receipt Generation
- Tax receipts generated upon ticket purchase
- Unique receipt hash for verification
- Block height timestamp for audit trail
- Queryable receipt history

### 📊 Impact Reporting
- Organizers publish detailed impact reports
- Shows total funds raised and allocated
- Attendee count tracking
- Transparent fund allocation reporting

### 👤 User Management
- Purchase up to 20 tickets per event
- View personal ticket history
- Access tax receipts anytime
- Verify ticket ownership

## Contract Structure

### Data Maps

**Events Map**
- Event details, pricing, and capacity
- Organizer information
- Real-time sales and fundraising stats
- Cause descriptions

**Tickets Map**
- Ticket ownership and validity
- Purchase amounts and dates
- Event association

**Tax Receipts Map**
- Receipt details and hashes
- Donation amounts
- Timestamp records

**Impact Reports Map**
- Post-event financial reporting
- Fund allocation details
- Attendee statistics

**User Tickets Map**
- User's ticket history per event
- Quick lookup for owned tickets

## Functions

### Public Functions

#### `create-event`
Creates a new fundraising event.

**Parameters:**
- `name` (string-ascii 100): Event name
- `ticket-price` (uint): Price per ticket in microSTX
- `total-tickets` (uint): Maximum tickets available
- `event-date` (uint): Event date (block height)
- `cause-description` (string-ascii 200): Description of the cause

**Returns:** Event ID (uint)

**Example:**
```clarity
(contract-call? .gala-pass create-event 
  "Charity Gala 2025" 
  u1000000 
  u100 
  u150000 
  "Supporting local education initiatives")
```

#### `purchase-ticket`
Purchase a ticket (make a donation) for an event.

**Parameters:**
- `event-id` (uint): The event to purchase for

**Returns:** Ticket ID (uint)

**Example:**
```clarity
(contract-call? .gala-pass purchase-ticket u1)
```

#### `generate-tax-receipt`
Manually generate a tax receipt for a ticket (auto-generated on purchase).

**Parameters:**
- `ticket-id` (uint): The ticket to generate receipt for

**Returns:** Receipt ID (uint)

#### `publish-impact-report`
Publish an impact report for an event (organizer only).

**Parameters:**
- `event-id` (uint): The event to report on
- `funds-allocated` (uint): Amount of funds allocated
- `report-description` (string-ascii 500): Detailed impact report

**Returns:** Boolean success

**Example:**
```clarity
(contract-call? .gala-pass publish-impact-report 
  u1 
  u95000000 
  "Funds allocated: 60% to scholarship programs, 30% to infrastructure, 10% to administration. Impact: 150 students supported.")
```

#### `deactivate-event`
Deactivate an event to stop ticket sales (organizer only).

**Parameters:**
- `event-id` (uint): Event to deactivate

**Returns:** Boolean success

### Read-Only Functions

#### `get-event`
Retrieve event details.

**Parameters:**
- `event-id` (uint)

**Returns:** Event data or none

#### `get-ticket`
Retrieve ticket details.

**Parameters:**
- `ticket-id` (uint)

**Returns:** Ticket data or none

#### `get-tax-receipt`
Retrieve tax receipt details.

**Parameters:**
- `receipt-id` (uint)

**Returns:** Receipt data or none

#### `get-impact-report`
Retrieve impact report for an event.

**Parameters:**
- `event-id` (uint)

**Returns:** Report data or none

#### `get-user-tickets`
Get all ticket IDs owned by a user for a specific event.

**Parameters:**
- `user` (principal): User address
- `event-id` (uint): Event ID

**Returns:** List of ticket IDs

#### `get-event-counter`
Get the total number of events created.

**Returns:** Event count (uint)

#### `get-ticket-counter`
Get the total number of tickets sold.

**Returns:** Ticket count (uint)

## Error Codes

| Code | Error | Description |
|------|-------|-------------|
| u100 | err-owner-only | Action requires contract owner |
| u101 | err-not-found | Resource not found |
| u102 | err-already-exists | Resource already exists |
| u103 | err-unauthorized | User not authorized |
| u104 | err-sold-out | Event tickets sold out |
| u105 | err-event-ended | Event is no longer active |
| u106 | err-invalid-amount | Invalid amount provided |

## Deployment

### Prerequisites
- Stacks blockchain node or access to testnet/mainnet
- Clarinet CLI tool
- STX tokens for deployment and testing

### Deploy Steps

1. **Test locally with Clarinet:**
```bash
clarinet test
```

2. **Deploy to testnet:**
```bash
clarinet deploy --testnet
```

3. **Deploy to mainnet:**
```bash
clarinet deploy --mainnet
```

## Usage Examples

### Scenario 1: Creating a Charity Event

```clarity
;; Organizer creates event
(contract-call? .gala-pass create-event 
  "Annual Charity Gala" 
  u5000000  ;; 5 STX per ticket
  u200      ;; 200 tickets available
  u160000   ;; Event at block 160000
  "Raising funds for children's healthcare")

;; Returns: (ok u1) - Event ID 1
```

### Scenario 2: Purchasing Tickets

```clarity
;; Donor purchases ticket
(contract-call? .gala-pass purchase-ticket u1)

;; Returns: (ok u1) - Ticket ID 1
;; Automatically generates tax receipt ID 1
```

### Scenario 3: Viewing Your Tickets

```clarity
;; Check your tickets for event 1
(contract-call? .gala-pass get-user-tickets tx-sender u1)

;; Returns: (u1 u2 u3) - List of your ticket IDs
```

### Scenario 4: Publishing Impact Report

```clarity
;; Organizer publishes post-event report
(contract-call? .gala-pass publish-impact-report 
  u1 
  u950000000  ;; 950 STX allocated
  "Successfully raised 1000 STX. Allocated 95% to healthcare programs serving 500 children. Remaining 5% covers operational costs.")

;; Returns: (ok true)
```

## Security Considerations

### Access Control
- Only event organizers can deactivate their events
- Only event organizers can publish impact reports
- Only ticket owners can generate receipts for their tickets

### Input Validation
- Event names must not be empty
- Ticket prices must be greater than zero
- Event dates must be in the future
- Total tickets must be greater than zero
- Report descriptions must not be empty

### Financial Safety
- STX transfers are atomic (all or nothing)
- Funds go directly to event organizers
- No funds held in contract
- All transactions are publicly auditable

## Best Practices

### For Event Organizers

1. **Set realistic ticket prices** - Consider your target audience
2. **Provide detailed cause descriptions** - Build trust with donors
3. **Publish impact reports promptly** - Maintain transparency
4. **Monitor ticket sales** - Use read-only functions to track progress

### For Donors

1. **Verify event details** - Use `get-event` before purchasing
2. **Save your tax receipts** - Query receipts after purchase
3. **Check impact reports** - See how your donation was used
4. **Verify ticket ownership** - Use `get-ticket` to confirm purchase

## Limitations

- Maximum 20 tickets per user per event (prevents hoarding)
- Receipt hash is simplified (consider integrating proper hash function)
- No refund mechanism (tickets are non-refundable donations)
- Events cannot be modified after creation (only deactivated)

## Future Enhancements

- [ ] Tiered ticket pricing (VIP, General, etc.)
- [ ] Multi-currency support
- [ ] Refund mechanism for cancelled events
- [ ] NFT tickets with metadata
- [ ] Integration with off-chain identity verification
- [ ] Automated impact report reminders
- [ ] Donor recognition system
- [ ] Event capacity updates
- [ ] Enhanced receipt hash generation

## Testing

Run the test suite using Clarinet:

```bash
# Run all tests
clarinet test

# Check contract syntax
clarinet check

# Run in console mode
clarinet console
```

### Example Test Cases

```clarity
;; Test 1: Create event successfully
(contract-call? .gala-pass create-event "Test Event" u1000000 u10 u50000 "Test cause")

;; Test 2: Purchase ticket
(contract-call? .gala-pass purchase-ticket u1)

;; Test 3: Verify ticket ownership
(contract-call? .gala-pass get-ticket u1)

;; Test 4: Check event stats
(contract-call? .gala-pass get-event u1)
```

## Contributing

Contributions are welcome! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch
3. Write tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## Support

For questions, issues, or feature requests:
- Open an issue on GitHub
- Check the Stacks documentation: https://docs.stacks.co

## Acknowledgments

Built with:
- [Stacks Blockchain](https://www.stacks.co/)
- [Clarity Language](https://clarity-lang.org/)
- [Clarinet Development Tool](https://github.com/hirosystems/clarinet)

---

**Disclaimer:** This smart contract is provided as-is. Always conduct thorough testing and auditing before deploying to mainnet with real funds.