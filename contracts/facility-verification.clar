;; Facility Verification Contract
;; Validates production sites and their credentials

(define-data-var admin principal tx-sender)

;; Data structure for facilities
(define-map facilities
  { facility-id: (string-ascii 32) }
  {
    owner: principal,
    name: (string-ascii 100),
    location: (string-ascii 100),
    certification-level: uint,
    verified: bool,
    registration-time: uint
  }
)

;; List of verified facility IDs
(define-data-var verified-facility-count uint u0)

;; Check if caller is admin
(define-private (is-admin)
  (is-eq tx-sender (var-get admin))
)

;; Register a new facility
(define-public (register-facility
    (facility-id (string-ascii 32))
    (name (string-ascii 100))
    (location (string-ascii 100))
  )
  (begin
    (asserts! (is-none (map-get? facilities {facility-id: facility-id})) (err u1)) ;; Facility ID must be unique
    (map-set facilities
      {facility-id: facility-id}
      {
        owner: tx-sender,
        name: name,
        location: location,
        certification-level: u0,
        verified: false,
        registration-time: block-height
      }
    )
    (ok true)
  )
)

;; Verify a facility (admin only)
(define-public (verify-facility (facility-id (string-ascii 32)) (certification-level uint))
  (begin
    (asserts! (is-admin) (err u403)) ;; Only admin can verify
    (asserts! (is-some (map-get? facilities {facility-id: facility-id})) (err u404)) ;; Facility must exist

    (let ((facility (unwrap-panic (map-get? facilities {facility-id: facility-id}))))
      (map-set facilities
        {facility-id: facility-id}
        (merge facility {
          verified: true,
          certification-level: certification-level
        })
      )
    )

    (var-set verified-facility-count (+ (var-get verified-facility-count) u1))
    (ok true)
  )
)

;; Check if a facility is verified
(define-read-only (is-facility-verified (facility-id (string-ascii 32)))
  (match (map-get? facilities {facility-id: facility-id})
    facility (ok (get verified facility))
    (err u404) ;; Facility not found
  )
)

;; Get facility details
(define-read-only (get-facility (facility-id (string-ascii 32)))
  (map-get? facilities {facility-id: facility-id})
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-admin) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)
