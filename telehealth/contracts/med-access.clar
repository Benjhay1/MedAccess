(define-constant contract-owner tx-sender)
(define-constant token-symbol "TMAT")
(define-constant token-name "TeleMed Access Token")
(define-constant token-decimals u6)

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

;; Error constants
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-AMOUNT (err u101))
(define-constant ERR-PROVIDER-NOT-VERIFIED (err u102))

;; Token operations
(define-public (transfer (amount uint) (sender principal) (recipient principal))
    (let ((sender-balance (default-to u0 (map-get? token-balances sender))))
        (if (and
                (>= sender-balance amount)
                (is-eq tx-sender sender))
            (begin
                (map-set token-balances sender (- sender-balance amount))
                (map-set token-balances recipient 
                    (+ (default-to u0 (map-get? token-balances recipient)) amount))
                (ok true))
            ERR-INVALID-AMOUNT)))

;; Provider registration
(define-public (register-provider (specialty (string-ascii 64)))
    (begin
        (map-set provider-credentials tx-sender
            {verified: false,
             specialty: specialty,
             last-verification: block-height,
             rating: u0})
        (ok true)))

;; Appointment booking
(define-public (book-appointment (provider principal) (timestamp uint) (tokens uint))
    (let ((provider-status (default-to 
            {verified: false, specialty: "", last-verification: u0, rating: u0}
            (map-get? provider-credentials provider))))
        (if (get verified provider-status)
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
        (if (is-eq (get provider appointment) tx-sender)
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
    (if (is-eq tx-sender contract-owner)
        (let ((credentials (unwrap! (map-get? provider-credentials provider)
                                  ERR-NOT-AUTHORIZED)))
            (begin
                (map-set provider-credentials provider
                    (merge credentials 
                        {verified: true,
                         last-verification: block-height}))
                (ok true)))
        ERR-NOT-AUTHORIZED))