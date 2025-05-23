;; Monetization Contract
;; Handles data usage payments

(define-data-var contract-owner principal tx-sender)
(define-data-var platform-fee-percent uint u5) ;; 5% platform fee

;; Data maps
(define-map data-pricing
  {
    vehicle-id: (string-utf8 36),
    data-type: (string-utf8 20)
  }
  {
    price-per-access: uint,
    owner: principal,
    is-available: bool
  }
)

(define-map data-access-records
  {
    access-id: (string-utf8 36)
  }
  {
    vehicle-id: (string-utf8 36),
    data-type: (string-utf8 20),
    consumer: principal,
    timestamp: uint,
    payment-amount: uint,
    is-processed: bool
  }
)

(define-map revenue-balances
  { owner: principal }
  { balance: uint }
)

;; Error codes
(define-constant ERR-NOT-AUTHORIZED u100)
(define-constant ERR-NOT-AVAILABLE u101)
(define-constant ERR-INSUFFICIENT-FUNDS u102)
(define-constant ERR-INVALID-PRICE u103)
(define-constant ERR-PAYMENT-FAILED u104)
(define-constant ERR-ALREADY-PROCESSED u105)

;; Read-only functions
(define-read-only (get-data-price (vehicle-id (string-utf8 36)) (data-type (string-utf8 20)))
  (map-get? data-pricing { vehicle-id: vehicle-id, data-type: data-type })
)

(define-read-only (get-access-record (access-id (string-utf8 36)))
  (map-get? data-access-records { access-id: access-id })
)

(define-read-only (get-balance (owner principal))
  (default-to u0 (get balance (map-get? revenue-balances { owner: owner })))
)

(define-read-only (get-platform-fee)
  (var-get platform-fee-percent)
)

;; Public functions
(define-public (set-data-price
    (vehicle-id (string-utf8 36))
    (data-type (string-utf8 20))
    (price-per-access uint)
    (is-available bool))
  (begin
    ;; In a real implementation, verify caller is vehicle owner
    ;; This would use contract-call? to the verification contract

    (asserts! (>= price-per-access u0) (err ERR-INVALID-PRICE))

    (map-set data-pricing
      { vehicle-id: vehicle-id, data-type: data-type }
      {
        price-per-access: price-per-access,
        owner: tx-sender,
        is-available: is-available
      }
    )
    (ok true)
  )
)

(define-public (purchase-data-access
    (vehicle-id (string-utf8 36))
    (data-type (string-utf8 20))
    (access-id (string-utf8 36)))
  (let (
    (pricing-info (get-data-price vehicle-id data-type))
  )
    (asserts! (is-some pricing-info) (err ERR-NOT-AVAILABLE))
    (let ((price-data (unwrap! pricing-info (err ERR-NOT-AVAILABLE))))
      (asserts! (get is-available price-data) (err ERR-NOT-AVAILABLE))

      (let (
        (price (get price-per-access price-data))
        (owner (get owner price-data))
        (platform-fee (/ (* price (var-get platform-fee-percent)) u100))
        (owner-payment (- price platform-fee))
      )
        ;; In a real implementation, this would use stx-transfer? to transfer tokens
        ;; For simplicity, we're just recording the access

        (map-set data-access-records
          { access-id: access-id }
          {
            vehicle-id: vehicle-id,
            data-type: data-type,
            consumer: tx-sender,
            timestamp: block-height,
            payment-amount: price,
            is-processed: false
          }
        )

        ;; Update owner's balance
        (map-set revenue-balances
          { owner: owner }
          { balance: (+ (get-balance owner) owner-payment) }
        )

        ;; Update platform balance
        (map-set revenue-balances
          { owner: (var-get contract-owner) }
          { balance: (+ (get-balance (var-get contract-owner)) platform-fee) }
        )

        (ok true)
      )
    )
  )
)

(define-public (withdraw-earnings)
  (let ((current-balance (get-balance tx-sender)))
    (asserts! (> current-balance u0) (err ERR-INSUFFICIENT-FUNDS))

    ;; In a real implementation, this would use stx-transfer? to transfer tokens
    ;; For simplicity, we're just resetting the balance

    (map-set revenue-balances
      { owner: tx-sender }
      { balance: u0 }
    )

    (ok current-balance)
  )
)

(define-public (set-platform-fee (new-fee-percent uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR-NOT-AUTHORIZED))
    (asserts! (<= new-fee-percent u20) (err ERR-INVALID-PRICE)) ;; Max 20% fee

    (var-set platform-fee-percent new-fee-percent)
    (ok true)
  )
)

(define-public (transfer-ownership (new-owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR-NOT-AUTHORIZED))
    (var-set contract-owner new-owner)
    (ok true)
  )
)
