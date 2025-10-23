;; Gala Pass - Fundraising Event Tickets with Donation Tracking
;; A transparent ticketing system for fundraising events

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-unauthorized (err u103))
(define-constant err-sold-out (err u104))
(define-constant err-event-ended (err u105))
(define-constant err-invalid-amount (err u106))

;; Data Variables
(define-data-var event-counter uint u0)
(define-data-var ticket-counter uint u0)
(define-data-var receipt-counter uint u0)

;; Data Maps
(define-map events
    uint
    {
        name: (string-ascii 100),
        organizer: principal,
        ticket-price: uint,
        total-tickets: uint,
        tickets-sold: uint,
        total-raised: uint,
        event-date: uint,
        is-active: bool,
        cause-description: (string-ascii 200)
    }
)

(define-map tickets
    uint
    {
        event-id: uint,
        owner: principal,
        purchase-amount: uint,
        purchase-date: uint,
        is-valid: bool
    }
)

(define-map tax-receipts
    uint
    {
        ticket-id: uint,
        attendee: principal,
        donation-amount: uint,
        receipt-date: uint,
        receipt-hash: (string-ascii 64)
    }
)

(define-map user-tickets
    { user: principal, event-id: uint }
    (list 20 uint)
)

(define-map impact-reports
    uint
    {
        event-id: uint,
        total-raised: uint,
        total-attendees: uint,
        funds-allocated: uint,
        report-description: (string-ascii 500),
        report-date: uint
    }
)

;; Read-only functions
(define-read-only (get-event (event-id uint))
    (map-get? events event-id)
)

(define-read-only (get-ticket (ticket-id uint))
    (map-get? tickets ticket-id)
)

(define-read-only (get-tax-receipt (receipt-id uint))
    (map-get? tax-receipts receipt-id)
)

(define-read-only (get-impact-report (event-id uint))
    (map-get? impact-reports event-id)
)

(define-read-only (get-user-tickets (user principal) (event-id uint))
    (default-to (list) (map-get? user-tickets { user: user, event-id: event-id }))
)

(define-read-only (get-event-counter)
    (ok (var-get event-counter))
)

(define-read-only (get-ticket-counter)
    (ok (var-get ticket-counter))
)

;; Public functions

;; Create a new fundraising event
(define-public (create-event 
    (name (string-ascii 100))
    (ticket-price uint)
    (total-tickets uint)
    (event-date uint)
    (cause-description (string-ascii 200)))
    (let
        ((new-event-id (+ (var-get event-counter) u1)))
        (asserts! (> ticket-price u0) err-invalid-amount)
        (asserts! (> total-tickets u0) err-invalid-amount)
        (asserts! (> (len name) u0) err-invalid-amount)
        (asserts! (> event-date stacks-block-height) err-invalid-amount)
        (map-set events new-event-id
            {
                name: name,
                organizer: tx-sender,
                ticket-price: ticket-price,
                total-tickets: total-tickets,
                tickets-sold: u0,
                total-raised: u0,
                event-date: event-date,
                is-active: true,
                cause-description: cause-description
            }
        )
        (var-set event-counter new-event-id)
        (ok new-event-id)
    )
)

;; Purchase a ticket (donation)
(define-public (purchase-ticket (event-id uint))
    (let
        (
            (event (unwrap! (map-get? events event-id) err-not-found))
            (ticket-price (get ticket-price event))
            (new-ticket-id (+ (var-get ticket-counter) u1))
            (current-tickets (get-user-tickets tx-sender event-id))
        )
        (asserts! (get is-active event) err-event-ended)
        (asserts! (< (get tickets-sold event) (get total-tickets event)) err-sold-out)
        
        ;; Transfer STX payment
        (try! (stx-transfer? ticket-price tx-sender (get organizer event)))
        
        ;; Create ticket
        (map-set tickets new-ticket-id
            {
                event-id: event-id,
                owner: tx-sender,
                purchase-amount: ticket-price,
                purchase-date: stacks-block-height,
                is-valid: true
            }
        )
        
        ;; Update event stats
        (map-set events event-id
            (merge event {
                tickets-sold: (+ (get tickets-sold event) u1),
                total-raised: (+ (get total-raised event) ticket-price)
            })
        )
        
        ;; Update user tickets list
        (map-set user-tickets 
            { user: tx-sender, event-id: event-id }
            (unwrap-panic (as-max-len? (append current-tickets new-ticket-id) u20))
        )
        
        (var-set ticket-counter new-ticket-id)
        
        ;; Generate tax receipt
        (try! (generate-tax-receipt new-ticket-id))
        
        (ok new-ticket-id)
    )
)

;; Generate tax receipt for a ticket
(define-public (generate-tax-receipt (ticket-id uint))
    (let
        (
            (ticket (unwrap! (map-get? tickets ticket-id) err-not-found))
            (new-receipt-id (+ (var-get receipt-counter) u1))
            (receipt-hash (generate-receipt-hash ticket-id))
        )
        (asserts! (is-eq tx-sender (get owner ticket)) err-unauthorized)
        
        (map-set tax-receipts new-receipt-id
            {
                ticket-id: ticket-id,
                attendee: tx-sender,
                donation-amount: (get purchase-amount ticket),
                receipt-date: stacks-block-height,
                receipt-hash: receipt-hash
            }
        )
        (var-set receipt-counter new-receipt-id)
        (ok new-receipt-id)
    )
)

;; Helper function to generate receipt hash
(define-private (generate-receipt-hash (ticket-id uint))
    ;; Simple receipt hash using ticket-id
    "RECEIPT-HASH"
)

;; Publish impact report (organizer only)
(define-public (publish-impact-report
    (event-id uint)
    (funds-allocated uint)
    (report-description (string-ascii 500)))
    (let
        ((event (unwrap! (map-get? events event-id) err-not-found)))
        (asserts! (is-eq tx-sender (get organizer event)) err-unauthorized)
        (asserts! (<= funds-allocated (get total-raised event)) err-invalid-amount)
        (asserts! (> (len report-description) u0) err-invalid-amount)
        
        (map-set impact-reports event-id
            {
                event-id: event-id,
                total-raised: (get total-raised event),
                total-attendees: (get tickets-sold event),
                funds-allocated: funds-allocated,
                report-description: report-description,
                report-date: stacks-block-height
            }
        )
        (ok true)
    )
)

;; Deactivate event (organizer only)
(define-public (deactivate-event (event-id uint))
    (let
        ((event (unwrap! (map-get? events event-id) err-not-found)))
        (asserts! (is-eq tx-sender (get organizer event)) err-unauthorized)
        
        (map-set events event-id
            (merge event { is-active: false })
        )
        (ok true)
    )
)

;; Initialize contract
(begin
    (var-set event-counter u0)
    (var-set ticket-counter u0)
    (var-set receipt-counter u0)
)