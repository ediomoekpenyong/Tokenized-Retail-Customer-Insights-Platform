;; Vehicle Verification Contract
;; Validates connected cars and maintains their verification status

(define-data-var contract-owner principal tx-sender)

;; Data maps
(define-map verified-vehicles
  { vehicle-id: (string-utf8 36) }
  {
    owner: principal,
    manufacturer: (string-utf8 50),
    model: (string-utf8 50),
    year: uint,
    is-verified: bool,
    verification-date: uint
  }
)

(define-map verification-authorities
  { authority-id: principal }
  { is-active: bool }
)

;; Error codes
(define-constant ERR-NOT-AUTHORIZED u100)
(define-constant ERR-ALREADY-VERIFIED u101)
(define-constant ERR-NOT-FOUND u102)
(define-constant ERR-ALREADY-REGISTERED u103)

;; Read-only functions
(define-read-only (get-vehicle-details (vehicle-id (string-utf8 36)))
  (map-get? verified-vehicles { vehicle-id: vehicle-id })
)

(define-read-only (is-authority (authority principal))
  (default-to false (get is-active (map-get? verification-authorities { authority-id: authority })))
)

(define-read-only (get-contract-owner)
  (var-get contract-owner)
)

;; Public functions
(define-public (register-vehicle
    (vehicle-id (string-utf8 36))
    (manufacturer (string-utf8 50))
    (model (string-utf8 50))
    (year uint))
  (let ((existing-vehicle (get-vehicle-details vehicle-id)))
    (asserts! (is-none existing-vehicle) (err ERR-ALREADY-REGISTERED))

    (map-set verified-vehicles
      { vehicle-id: vehicle-id }
      {
        owner: tx-sender,
        manufacturer: manufacturer,
        model: model,
        year: year,
        is-verified: false,
        verification-date: u0
      }
    )
    (ok true)
  )
)

(define-public (verify-vehicle (vehicle-id (string-utf8 36)))
  (let ((vehicle-data (get-vehicle-details vehicle-id)))
    (asserts! (is-authority tx-sender) (err ERR-NOT-AUTHORIZED))
    (asserts! (is-some vehicle-data) (err ERR-NOT-FOUND))
    (asserts! (not (get is-verified (unwrap! vehicle-data (err ERR-NOT-FOUND)))) (err ERR-ALREADY-VERIFIED))

    (map-set verified-vehicles
      { vehicle-id: vehicle-id }
      (merge (unwrap! vehicle-data (err ERR-NOT-FOUND))
        {
          is-verified: true,
          verification-date: block-height
        }
      )
    )
    (ok true)
  )
)

(define-public (add-verification-authority (authority principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR-NOT-AUTHORIZED))
    (map-set verification-authorities
      { authority-id: authority }
      { is-active: true }
    )
    (ok true)
  )
)

(define-public (remove-verification-authority (authority principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR-NOT-AUTHORIZED))
    (map-set verification-authorities
      { authority-id: authority }
      { is-active: false }
    )
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
