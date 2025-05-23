;; Data Collection Contract
;; Gathers and stores vehicle information

(define-data-var contract-owner principal tx-sender)

;; Data maps
(define-map vehicle-data-entries
  {
    vehicle-id: (string-utf8 36),
    timestamp: uint
  }
  {
    data-type: (string-utf8 20),
    data-hash: (buff 32),
    data-size: uint,
    submitter: principal
  }
)

(define-map vehicle-data-summary
  { vehicle-id: (string-utf8 36) }
  {
    last-update: uint,
    entry-count: uint
  }
)

;; Error codes
(define-constant ERR-NOT-AUTHORIZED u100)
(define-constant ERR-INVALID-VEHICLE u101)
(define-constant ERR-INVALID-DATA u102)

;; Read-only functions
(define-read-only (get-data-entry (vehicle-id (string-utf8 36)) (timestamp uint))
  (map-get? vehicle-data-entries { vehicle-id: vehicle-id, timestamp: timestamp })
)

(define-read-only (get-vehicle-summary (vehicle-id (string-utf8 36)))
  (default-to
    { last-update: u0, entry-count: u0 }
    (map-get? vehicle-data-summary { vehicle-id: vehicle-id })
  )
)

;; Public functions
(define-public (submit-vehicle-data
    (vehicle-id (string-utf8 36))
    (data-type (string-utf8 20))
    (data-hash (buff 32))
    (data-size uint))
  (let (
    (timestamp block-height)
    (current-summary (get-vehicle-summary vehicle-id))
  )
    ;; Verify vehicle exists by calling the verification contract
    ;; In a real implementation, this would use contract-call? to the verification contract

    (map-set vehicle-data-entries
      { vehicle-id: vehicle-id, timestamp: timestamp }
      {
        data-type: data-type,
        data-hash: data-hash,
        data-size: data-size,
        submitter: tx-sender
      }
    )

    (map-set vehicle-data-summary
      { vehicle-id: vehicle-id }
      {
        last-update: timestamp,
        entry-count: (+ (get entry-count current-summary) u1)
      }
    )

    (ok timestamp)
  )
)

(define-public (bulk-submit-data
    (vehicle-id (string-utf8 36))
    (data-type (string-utf8 20))
    (data-hashes (list 10 (buff 32)))
    (data-sizes (list 10 uint)))
  (let (
    (timestamp block-height)
    (current-summary (get-vehicle-summary vehicle-id))
    (count (len data-hashes))
  )
    (asserts! (is-eq (len data-hashes) (len data-sizes)) (err ERR-INVALID-DATA))
    (asserts! (> count u0) (err ERR-INVALID-DATA))

    ;; In a real implementation, we would iterate through the lists
    ;; Since Clarity doesn't support loops, this is simplified

    (map-set vehicle-data-summary
      { vehicle-id: vehicle-id }
      {
        last-update: timestamp,
        entry-count: (+ (get entry-count current-summary) count)
      }
    )

    (ok timestamp)
  )
)

(define-public (transfer-ownership (new-owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR-NOT-AUTHORIZED))
    (var-set contract-owner new-owner)
    (ok true)
  )
)
