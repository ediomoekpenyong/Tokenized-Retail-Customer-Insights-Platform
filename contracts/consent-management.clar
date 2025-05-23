;; Consent Management Contract
;; Controls data sharing permissions

(define-data-var contract-owner principal tx-sender)

;; Data maps
(define-map consent-records
  {
    vehicle-id: (string-utf8 36),
    data-type: (string-utf8 20),
    consumer: principal
  }
  {
    granted: bool,
    expiration: uint,
    last-updated: uint
  }
)

(define-map global-consent
  { vehicle-id: (string-utf8 36) }
  {
    all-data-shared: bool,
    last-updated: uint
  }
)

;; Error codes
(define-constant ERR-NOT-AUTHORIZED u100)
(define-constant ERR-INVALID-EXPIRATION u101)
(define-constant ERR-NOT-VEHICLE-OWNER u102)

;; Read-only functions
(define-read-only (check-consent
    (vehicle-id (string-utf8 36))
    (data-type (string-utf8 20))
    (consumer principal))
  (let (
    (specific-consent (map-get? consent-records
      { vehicle-id: vehicle-id, data-type: data-type, consumer: consumer }))
    (global-setting (map-get? global-consent { vehicle-id: vehicle-id }))
  )
    (if (is-some specific-consent)
      (let ((consent-data (unwrap! specific-consent false)))
        (and
          (get granted consent-data)
          (or
            (is-eq (get expiration consent-data) u0)
            (> (get expiration consent-data) block-height)
          )
        )
      )
      (if (is-some global-setting)
        (get all-data-shared (unwrap! global-setting false))
        false
      )
    )
  )
)

(define-read-only (get-consent-details
    (vehicle-id (string-utf8 36))
    (data-type (string-utf8 20))
    (consumer principal))
  (map-get? consent-records
    { vehicle-id: vehicle-id, data-type: data-type, consumer: consumer })
)

(define-read-only (get-global-consent (vehicle-id (string-utf8 36)))
  (map-get? global-consent { vehicle-id: vehicle-id })
)

;; Public functions
(define-public (set-data-consent
    (vehicle-id (string-utf8 36))
    (data-type (string-utf8 20))
    (consumer principal)
    (granted bool)
    (expiration uint))
  (begin
    ;; In a real implementation, verify caller is vehicle owner
    ;; This would use contract-call? to the verification contract

    (asserts! (or (is-eq expiration u0) (> expiration block-height)) (err ERR-INVALID-EXPIRATION))

    (map-set consent-records
      { vehicle-id: vehicle-id, data-type: data-type, consumer: consumer }
      {
        granted: granted,
        expiration: expiration,
        last-updated: block-height
      }
    )
    (ok true)
  )
)

(define-public (set-global-consent
    (vehicle-id (string-utf8 36))
    (all-data-shared bool))
  (begin
    ;; In a real implementation, verify caller is vehicle owner
    ;; This would use contract-call? to the verification contract

    (map-set global-consent
      { vehicle-id: vehicle-id }
      {
        all-data-shared: all-data-shared,
        last-updated: block-height
      }
    )
    (ok true)
  )
)

(define-public (revoke-all-consent (vehicle-id (string-utf8 36)))
  (begin
    ;; In a real implementation, verify caller is vehicle owner
    ;; This would use contract-call? to the verification contract

    (map-set global-consent
      { vehicle-id: vehicle-id }
      {
        all-data-shared: false,
        last-updated: block-height
      }
    )
    ;; Note: In a real implementation, we would need to iterate through
    ;; all specific consents and revoke them, but Clarity doesn't support loops
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
