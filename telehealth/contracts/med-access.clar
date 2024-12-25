(define-constant contract-owner tx-sender)
(define-constant token-symbol "TMAT")
(define-constant token-name "TeleMed Access Token")
(define-constant token-decimals u6)
(define-constant MAX-UINT u340282366920938463463374607431768211455)

;; Error constants
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-AMOUNT (err u101))
(define-constant ERR-PROVIDER-NOT-VERIFIED (err u102))
(define-constant ERR-INVALID-RECIPIENT (err u103))
(define-constant ERR-INVALID-PROVIDER (err u104))
(define-constant ERR-INVALID-TIMESTAMP (err u105))
(define-constant ERR-ZERO-AMOUNT (err u106))
(define-constant ERR-INVALID-SPECIALTY (err u107))

;; Data Maps
(define-map provider-credentials 
    principal 
    {verified: bool, 
     specialty: (string-ascii 64), 
     last-verification: uint,
     rating: uint})

(define-map appointments
    uint
    {patient: principal,
     provider: principal,
     timestamp: uint,
     status: (string-ascii 20),
     tokens-staked: uint})

(define-map token-balances principal uint)
(define-data-var appointment-nonce uint u0)

;; Helper functions for validation
(define-private (is-valid-recipient (recipient principal))
    (and 
        (not (is-eq recipient (as-contract tx-sender)))
        (not (is-eq recipient contract-owner))))

(define-private (is-valid-timestamp (timestamp uint))
    (and 
        (> timestamp block-height)
        (< timestamp (+ block-height u525600)))) ;; Max 1 year ahead

(define-private (is-valid-amount (amount uint))
    (and 
        (> amount u0)
        (< amount MAX-UINT)))

(define-private (is-valid-specialty (specialty (string-ascii 64)))
    (and
        (> (len specialty) u0)
        (< (len specialty) u64)))

;; Token operations
(define-public (transfer (amount uint) (sender principal) (recipient principal))
    (let ((sender-balance (default-to u0 (map-get? token-balances sender))))
        (if (and
                (>= sender-balance amount)
                (is-eq tx-sender sender)
                (asserts! (is-valid-recipient recipient) ERR-INVALID-RECIPIENT)
                (asserts! (is-valid-amount amount) ERR-INVALID-AMOUNT))
            (begin
                (map-set token-balances sender (- sender-balance amount))
                (map-set token-balances recipient 
                    (+ (default-to u0 (map-get? token-balances recipient)) amount))
                (ok true))
            ERR-INVALID-AMOUNT)))

;; Provider registration
(define-public (register-provider (specialty (string-ascii 64)))
    (if (and 
            (is-valid-recipient tx-sender)
            (asserts! (is-valid-specialty specialty) ERR-INVALID-SPECIALTY))
        (begin
            (map-set provider-credentials tx-sender
                {verified: false,
                 specialty: specialty,
                 last-verification: block-height,
                 rating: u0})
            (ok true))
        ERR-INVALID-PROVIDER))

;; Appointment booking
(define-public (book-appointment (provider principal) (timestamp uint) (tokens uint))
    (let ((provider-status (default-to 
            {verified: false, specialty: "", last-verification: u0, rating: u0}
            (map-get? provider-credentials provider))))
        (if (and 
                (get verified provider-status)
                (asserts! (is-valid-recipient provider) ERR-INVALID-PROVIDER)
                (asserts! (is-valid-timestamp timestamp) ERR-INVALID-TIMESTAMP)
                (asserts! (is-valid-amount tokens) ERR-INVALID-AMOUNT))
            (let ((appointment-id (var-get appointment-nonce)))
                (begin
                    (try! (transfer tokens tx-sender (as-contract tx-sender)))
                    (map-set appointments appointment-id
                        {patient: tx-sender,
                         provider: provider,
                         timestamp: timestamp,
                         status: "scheduled",
                         tokens-staked: tokens})
                    (var-set appointment-nonce (+ appointment-id u1))
                    (ok appointment-id)))
            ERR-PROVIDER-NOT-VERIFIED)))

;; Complete appointment and release payment
(define-public (complete-appointment (appointment-id uint))
    (let ((appointment (unwrap! (map-get? appointments appointment-id)
                               ERR-NOT-AUTHORIZED)))
        (if (and 
                (is-eq (get provider appointment) tx-sender)
                (asserts! (is-valid-recipient (get provider appointment)) ERR-INVALID-PROVIDER))
            (begin
                (try! (transfer 
                    (get tokens-staked appointment)
                    (as-contract tx-sender)
                    (get provider appointment)))
                (map-set appointments appointment-id
                    (merge appointment {status: "completed"}))
                (ok true))
            ERR-NOT-AUTHORIZED)))

;; Provider verification
(define-public (verify-provider (provider principal))
    (if (and 
            (is-eq tx-sender contract-owner)
            (asserts! (is-valid-recipient provider) ERR-INVALID-PROVIDER))
        (let ((credentials (unwrap! (map-get? provider-credentials provider)
                                  ERR-NOT-AUTHORIZED)))
            (begin
                (map-set provider-credentials provider
                    (merge credentials 
                        {verified: true,
                         last-verification: block-height}))
                (ok true)))
        ERR-NOT-AUTHORIZED))