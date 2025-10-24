;; Dividend Payout System Smart Contract

;; Constants
(define-constant treasury-controller tx-sender)
(define-constant err-controller-only (err u100))
(define-constant err-dividend-withdrawn (err u101))
(define-constant err-not-shareholder (err u102))
(define-constant err-no-dividend-allocation (err u103))
(define-constant err-payout-suspended (err u104))
(define-constant err-invalid-investor (err u105))
(define-constant err-invalid-payout (err u106))

;; Data Variables
(define-data-var total-dividend-pool uint u5000000)
(define-data-var payout-active bool false)

;; Data Maps
(define-map investor-dividends principal uint)       ;; Maps investors to dividend amount
(define-map withdrawal-records principal bool)       ;; Tracks withdrawal status
(define-map share-certificates principal bool)       ;; Share certificate verification
(define-map accredited-investors principal bool)     ;; Accredited investor list

;; Private Functions
(define-private (is-treasury-controller)
    (is-eq tx-sender treasury-controller))

(define-private (is-verified-shareholder (investor principal))
    (and 
        (is-some (map-get? accredited-investors investor))
        (is-some (map-get? share-certificates investor))))

(define-private (validate-investor (investor principal))
    (and
        (is-some (some investor))
        (not (is-eq investor treasury-controller))))

;; Public Functions

;; Accredit investor (controller only)
(define-public (accredit-investor (investor principal))
    (begin
        (asserts! (is-treasury-controller) err-controller-only)
        (asserts! (validate-investor investor) err-invalid-investor)
        (ok (map-set accredited-investors investor true))))

;; Remove accreditation (controller only)
(define-public (remove-accreditation (investor principal))
    (begin
        (asserts! (is-treasury-controller) err-controller-only)
        (asserts! (validate-investor investor) err-invalid-investor)
        (ok (map-set accredited-investors investor false))))

;; Issue share certificate (controller only)
(define-public (issue-certificate (investor principal) (has-shares bool))
    (begin
        (asserts! (is-treasury-controller) err-controller-only)
        (asserts! (validate-investor investor) err-invalid-investor)
        (ok (map-set share-certificates investor has-shares))))

;; Set dividend allocation (controller only)
(define-public (set-dividend-allocation (investor principal) (payout uint))
    (begin
        (asserts! (is-treasury-controller) err-controller-only)
        (asserts! (validate-investor investor) err-invalid-investor)
        (asserts! (> payout u0) err-invalid-payout)
        (asserts! (<= payout (var-get total-dividend-pool)) err-invalid-payout)
        (ok (map-set investor-dividends investor payout))))

;; Withdraw dividend (public)
(define-public (withdraw-dividend)
    (let ((investor tx-sender)
          (dividend-payout (unwrap! (map-get? investor-dividends investor) err-no-dividend-allocation)))
        (begin
            (asserts! (var-get payout-active) err-payout-suspended)
            (asserts! (is-verified-shareholder investor) err-not-shareholder)
            (asserts! (not (default-to false (map-get? withdrawal-records investor))) err-dividend-withdrawn)
            (map-set withdrawal-records investor true)
            (ok dividend-payout))))

;; Mass dividend distribution (controller only)
(define-public (mass-dividend-distribution (investors (list 200 principal)) (payouts (list 200 uint)))
    (begin
        (asserts! (is-treasury-controller) err-controller-only)
        (asserts! (is-eq (len investors) (len payouts)) err-invalid-payout)
        (asserts! 
            (fold and 
                (map validate-investor investors) 
                true) 
            err-invalid-investor)
        (asserts! 
            (fold and 
                (map is-valid-payout payouts)
                true) 
            err-invalid-payout)
        (ok true)))

(define-private (is-valid-payout (payout uint))
    (> payout u0))

;; Toggle payout window (controller only)
(define-public (toggle-payout)
    (begin
        (asserts! (is-treasury-controller) err-controller-only)
        (ok (var-set payout-active (not (var-get payout-active))))))

;; Read-only functions

(define-read-only (get-dividend-allocation (investor principal))
    (default-to u0 (map-get? investor-dividends investor)))

(define-read-only (has-withdrawn (investor principal))
    (default-to false (map-get? withdrawal-records investor)))

(define-read-only (verify-shareholder (investor principal))
    (is-verified-shareholder investor))

(define-read-only (is-payout-active)
    (var-get payout-active))

(define-read-only (get-dividend-pool)
    (var-get total-dividend-pool))

(define-read-only (get-investor-details (investor principal))
    {
        dividend: (get-dividend-allocation investor),
        withdrawn: (has-withdrawn investor),
        shareholder: (verify-shareholder investor),
        accredited: (default-to false (map-get? accredited-investors investor)),
        has-certificate: (default-to false (map-get? share-certificates investor)),
        can-withdraw: (and 
            (var-get payout-active)
            (verify-shareholder investor)
            (not (has-withdrawn investor))
            (> (get-dividend-allocation investor) u0)
        )
    })