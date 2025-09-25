;; RareAssets - Synthetic trading of rare metals, vintage wines, and luxury collectibles
;; Built on Stacks blockchain using Clarity

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-UNAUTHORIZED (err u100))
(define-constant ERR-INSUFFICIENT-BALANCE (err u101))
(define-constant ERR-ASSET-NOT-FOUND (err u102))
(define-constant ERR-INVALID-AMOUNT (err u103))
(define-constant ERR-POSITION-NOT-FOUND (err u104))
(define-constant ERR-INVALID-PRICE (err u105))

;; Asset types
(define-constant RARE-METALS u1)
(define-constant VINTAGE-WINES u2)
(define-constant LUXURY-COLLECTIBLES u3)

;; Data Variables
(define-data-var next-asset-id uint u1)
(define-data-var next-position-id uint u1)
(define-data-var protocol-fee uint u25) ;; 0.25% in basis points

;; Data Maps
;; Asset definitions
(define-map assets
  uint
  {
    name: (string-ascii 50),
    asset-type: uint,
    price-per-unit: uint,
    total-supply: uint,
    active: bool
  }
)

;; User positions
(define-map positions
  uint
  {
    owner: principal,
    asset-id: uint,
    amount: uint,
    entry-price: uint,
    timestamp: uint
  }
)

;; User balances (STX collateral)
(define-map user-balances principal uint)

;; Asset ownership tracking
(define-map user-assets
  {user: principal, asset-id: uint}
  uint
)

;; Read-only functions
(define-read-only (get-asset (asset-id uint))
  (map-get? assets asset-id)
)

(define-read-only (get-position (position-id uint))
  (map-get? positions position-id)
)

(define-read-only (get-user-balance (user principal))
  (default-to u0 (map-get? user-balances user))
)

(define-read-only (get-user-asset-amount (user principal) (asset-id uint))
  (default-to u0 (map-get? user-assets {user: user, asset-id: asset-id}))
)

(define-read-only (get-protocol-fee)
  (var-get protocol-fee)
)

(define-read-only (get-next-asset-id)
  (var-get next-asset-id)
)

(define-read-only (get-next-position-id)
  (var-get next-position-id)
)

;; Private functions
(define-private (is-contract-owner)
  (is-eq tx-sender CONTRACT-OWNER)
)

(define-private (calculate-fee (amount uint))
  (/ (* amount (var-get protocol-fee)) u10000)
)

;; Public functions

;; Initialize contract owner balance
(define-public (initialize)
  (begin
    (asserts! (is-contract-owner) ERR-UNAUTHORIZED)
    (ok true)
  )
)

;; Add new synthetic asset (only contract owner)
(define-public (add-asset (name (string-ascii 50)) (asset-type uint) (initial-price uint))
  (let (
    (asset-id (var-get next-asset-id))
  )
    (asserts! (is-contract-owner) ERR-UNAUTHORIZED)
    (asserts! (> initial-price u0) ERR-INVALID-PRICE)
    (asserts! (or (is-eq asset-type RARE-METALS) 
                  (is-eq asset-type VINTAGE-WINES) 
                  (is-eq asset-type LUXURY-COLLECTIBLES)) ERR-ASSET-NOT-FOUND)
    
    (map-set assets asset-id
      {
        name: name,
        asset-type: asset-type,
        price-per-unit: initial-price,
        total-supply: u0,
        active: true
      }
    )
    (var-set next-asset-id (+ asset-id u1))
    (ok asset-id)
  )
)

;; Update asset price (only contract owner)
(define-public (update-asset-price (asset-id uint) (new-price uint))
  (let (
    (asset (unwrap! (map-get? assets asset-id) ERR-ASSET-NOT-FOUND))
  )
    (asserts! (is-contract-owner) ERR-UNAUTHORIZED)
    (asserts! (> new-price u0) ERR-INVALID-PRICE)
    
    (map-set assets asset-id
      (merge asset {price-per-unit: new-price})
    )
    (ok true)
  )
)

;; Deposit STX collateral
(define-public (deposit-collateral (amount uint))
  (let (
    (current-balance (get-user-balance tx-sender))
  )
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (map-set user-balances tx-sender (+ current-balance amount))
    (ok true)
  )
)

;; Withdraw STX collateral
(define-public (withdraw-collateral (amount uint))
  (let (
    (current-balance (get-user-balance tx-sender))
  )
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (asserts! (>= current-balance amount) ERR-INSUFFICIENT-BALANCE)
    
    (try! (as-contract (stx-transfer? amount tx-sender tx-sender)))
    (map-set user-balances tx-sender (- current-balance amount))
    (ok true)
  )
)

;; Open long position (buy synthetic asset)
(define-public (open-long-position (asset-id uint) (amount uint))
  (let (
    (asset (unwrap! (map-get? assets asset-id) ERR-ASSET-NOT-FOUND))
    (position-id (var-get next-position-id))
    (total-cost (* amount (get price-per-unit asset)))
    (fee (calculate-fee total-cost))
    (total-with-fee (+ total-cost fee))
    (user-balance (get-user-balance tx-sender))
    (current-user-amount (get-user-asset-amount tx-sender asset-id))
  )
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (asserts! (get active asset) ERR-ASSET-NOT-FOUND)
    (asserts! (>= user-balance total-with-fee) ERR-INSUFFICIENT-BALANCE)
    
    ;; Update user balance
    (map-set user-balances tx-sender (- user-balance total-with-fee))
    
    ;; Create position
    (map-set positions position-id
      {
        owner: tx-sender,
        asset-id: asset-id,
        amount: amount,
        entry-price: (get price-per-unit asset),
        timestamp: stacks-block-height
      }
    )
    
    ;; Update user asset holdings
    (map-set user-assets {user: tx-sender, asset-id: asset-id} 
             (+ current-user-amount amount))
    
    ;; Update asset total supply
    (map-set assets asset-id
      (merge asset {total-supply: (+ (get total-supply asset) amount)})
    )
    
    (var-set next-position-id (+ position-id u1))
    (ok position-id)
  )
)

;; Close position (sell synthetic asset)
(define-public (close-position (position-id uint))
  (let (
    (position (unwrap! (map-get? positions position-id) ERR-POSITION-NOT-FOUND))
    (asset (unwrap! (map-get? assets (get asset-id position)) ERR-ASSET-NOT-FOUND))
    (total-value (* (get amount position) (get price-per-unit asset)))
    (fee (calculate-fee total-value))
    (net-value (- total-value fee))
    (user-balance (get-user-balance tx-sender))
    (current-user-amount (get-user-asset-amount tx-sender (get asset-id position)))
  )
    (asserts! (is-eq tx-sender (get owner position)) ERR-UNAUTHORIZED)
    (asserts! (>= current-user-amount (get amount position)) ERR-INSUFFICIENT-BALANCE)
    
    ;; Update user balance
    (map-set user-balances tx-sender (+ user-balance net-value))
    
    ;; Update user asset holdings
    (map-set user-assets {user: tx-sender, asset-id: (get asset-id position)} 
             (- current-user-amount (get amount position)))
    
    ;; Update asset total supply
    (map-set assets (get asset-id position)
      (merge asset {total-supply: (- (get total-supply asset) (get amount position))})
    )
    
    ;; Remove position
    (map-delete positions position-id)
    (ok net-value)
  )
)

;; Set protocol fee (only contract owner)
(define-public (set-protocol-fee (new-fee uint))
  (begin
    (asserts! (is-contract-owner) ERR-UNAUTHORIZED)
    (asserts! (<= new-fee u1000) ERR-INVALID-AMOUNT) ;; Max 10% fee
    (var-set protocol-fee new-fee)
    (ok true)
  )
)

;; Emergency pause asset (only contract owner)
(define-public (pause-asset (asset-id uint))
  (let (
    (asset (unwrap! (map-get? assets asset-id) ERR-ASSET-NOT-FOUND))
  )
    (asserts! (is-contract-owner) ERR-UNAUTHORIZED)
    
    (map-set assets asset-id
      (merge asset {active: false})
    )
    (ok true)
  )
)

;; Reactivate asset (only contract owner)
(define-public (reactivate-asset (asset-id uint))
  (let (
    (asset (unwrap! (map-get? assets asset-id) ERR-ASSET-NOT-FOUND))
  )
    (asserts! (is-contract-owner) ERR-UNAUTHORIZED)
    
    (map-set assets asset-id
      (merge asset {active: true})
    )
    (ok true)
  )
)