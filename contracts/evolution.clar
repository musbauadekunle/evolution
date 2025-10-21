;; Evolutionary NFT Contract
;; NFTs that mutate attributes based on random or user-driven events

;; constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-token-owner (err u101))
(define-constant err-token-exists (err u102))
(define-constant err-token-not-found (err u103))
(define-constant err-cooldown-active (err u104))

;; Evolution cooldown period (blocks)
(define-constant evolution-cooldown u144) ;; ~24 hours on Stacks

;; data vars
(define-data-var last-token-id uint u0)

;; data maps
;; NFT ownership
(define-map nft-owners uint principal)

;; NFT attributes - stored as simple numeric values
(define-map nft-attributes uint {
    color: uint,        ;; 0-255
    size: uint,         ;; 0-100
    speed: uint,        ;; 0-100
    strength: uint,     ;; 0-100
    generation: uint,   ;; evolution count
    last-evolution: uint ;; block height of last evolution
})

;; Evolution history tracking
(define-map evolution-count principal uint)

;; public functions

;; Mint a new NFT with random initial attributes
(define-public (mint-nft)
    (let
        (
            (token-id (+ (var-get last-token-id) u1))
            (random-seed (unwrap-panic (get-block-info? vrf-seed (- block-height u1))))
        )
        ;; Update last token ID
        (var-set last-token-id token-id)

        ;; Set owner
        (map-set nft-owners token-id tx-sender)

        ;; Set initial random attributes
        (map-set nft-attributes token-id {
            color: (mod (buff-to-uint random-seed) u256),
            size: (mod (buff-to-uint random-seed) u100),
            speed: u50,
            strength: u50,
            generation: u0,
            last-evolution: block-height
        })

        (ok token-id)
    )
)

;; Random evolution - uses VRF for randomness
(define-public (evolve-random (token-id uint))
    (let
        (
            (owner (unwrap! (map-get? nft-owners token-id) err-token-not-found))
            (attrs (unwrap! (map-get? nft-attributes token-id) err-token-not-found))
            (random-seed (unwrap-panic (get-block-info? vrf-seed (- block-height u1))))
            (random-val (buff-to-uint random-seed))
        )
        ;; Check ownership
        (asserts! (is-eq tx-sender owner) err-not-token-owner)

        ;; Check cooldown
        (asserts! (>= (- block-height (get last-evolution attrs)) evolution-cooldown) err-cooldown-active)

        ;; Apply random mutations
        (map-set nft-attributes token-id {
            color: (mod (+ (get color attrs) (mod random-val u50)) u256),
            size: (mod (+ (get size attrs) (mod (/ random-val u2) u20)) u100),
            speed: (mod (+ (get speed attrs) (mod (/ random-val u3) u20)) u100),
            strength: (mod (+ (get strength attrs) (mod (/ random-val u5) u20)) u100),
            generation: (+ (get generation attrs) u1),
            last-evolution: block-height
        })

        ;; Track evolution count for sender
        (map-set evolution-count tx-sender
            (+ (default-to u0 (map-get? evolution-count tx-sender)) u1))

        (ok true)
    )
)

;; User-driven evolution - choose which attribute to boost
(define-public (evolve-boost (token-id uint) (attribute (string-ascii 10)))
    (let
        (
            (owner (unwrap! (map-get? nft-owners token-id) err-token-not-found))
            (attrs (unwrap! (map-get? nft-attributes token-id) err-token-not-found))
            (boost-amount u15)
        )
        ;; Check ownership
        (asserts! (is-eq tx-sender owner) err-not-token-owner)

        ;; Check cooldown
        (asserts! (>= (- block-height (get last-evolution attrs)) evolution-cooldown) err-cooldown-active)

        ;; Apply targeted boost based on chosen attribute
        (if (is-eq attribute "speed")
            (map-set nft-attributes token-id (merge attrs {
                speed: (mod (+ (get speed attrs) boost-amount) u100),
                generation: (+ (get generation attrs) u1),
                last-evolution: block-height
            }))
            (if (is-eq attribute "strength")
                (map-set nft-attributes token-id (merge attrs {
                    strength: (mod (+ (get strength attrs) boost-amount) u100),
                    generation: (+ (get generation attrs) u1),
                    last-evolution: block-height
                }))
                (if (is-eq attribute "size")
                    (map-set nft-attributes token-id (merge attrs {
                        size: (mod (+ (get size attrs) boost-amount) u100),
                        generation: (+ (get generation attrs) u1),
                        last-evolution: block-height
                    }))
                    ;; Default to color
                    (map-set nft-attributes token-id (merge attrs {
                        color: (mod (+ (get color attrs) u30) u256),
                        generation: (+ (get generation attrs) u1),
                        last-evolution: block-height
                    }))
                )
            )
        )

        ;; Track evolution count
        (map-set evolution-count tx-sender
            (+ (default-to u0 (map-get? evolution-count tx-sender)) u1))

        (ok true)
    )
)

;; Transfer NFT ownership
(define-public (transfer (token-id uint) (recipient principal))
    (let
        (
            (owner (unwrap! (map-get? nft-owners token-id) err-token-not-found))
        )
        (asserts! (is-eq tx-sender owner) err-not-token-owner)
        (map-set nft-owners token-id recipient)
        (ok true)
    )
)

;; read only functions

;; Get NFT owner
(define-read-only (get-owner (token-id uint))
    (ok (map-get? nft-owners token-id))
)

;; Get NFT attributes
(define-read-only (get-attributes (token-id uint))
    (ok (map-get? nft-attributes token-id))
)

;; Get last token ID
(define-read-only (get-last-token-id)
    (ok (var-get last-token-id))
)

;; Get evolution count for a user
(define-read-only (get-user-evolution-count (user principal))
    (ok (default-to u0 (map-get? evolution-count user)))
)

;; Check if evolution is available (cooldown passed)
(define-read-only (can-evolve (token-id uint))
    (match (map-get? nft-attributes token-id)
        attrs (ok (>= (- block-height (get last-evolution attrs)) evolution-cooldown))
        (ok false)
    )
)

;; Get blocks until next evolution is available
(define-read-only (blocks-until-evolution (token-id uint))
    (match (map-get? nft-attributes token-id)
        attrs
            (let ((blocks-passed (- block-height (get last-evolution attrs))))
                (if (>= blocks-passed evolution-cooldown)
                    (ok u0)
                    (ok (- evolution-cooldown blocks-passed))
                )
            )
        err-token-not-found
    )
)

;; private functions

;; Convert buffer to uint for randomness
(define-private (buff-to-uint (buffer (buff 32)))
    (let
        (
            (byte-list (unwrap-panic (as-max-len? (list
                (buff-to-uint-8 (unwrap-panic (element-at buffer u0)))
                (buff-to-uint-8 (unwrap-panic (element-at buffer u1)))
                (buff-to-uint-8 (unwrap-panic (element-at buffer u2)))
                (buff-to-uint-8 (unwrap-panic (element-at buffer u3)))
            ) u4)))
        )
        (fold + byte-list u0)
    )
)

;; Convert single byte to uint
(define-private (buff-to-uint-8 (byte (buff 1)))
    (unwrap-panic (index-of 0x000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f404142434445464748494a4b4c4d4e4f505152535455565758595a5b5c5d5e5f606162636465666768696a6b6c6d6e6f707172737475767778797a7b7c7d7e7f808182838485868788898a8b8c8d8e8f909192939495969798999a9b9c9d9e9fa0a1a2a3a4a5a6a7a8a9aaabacadaeafb0b1b2b3b4b5b6b7b8b9babbbcbdbebfc0c1c2c3c4c5c6c7c8c9cacbcccdcecfd0d1d2d3d4d5d6d7d8d9dadbdcdddedfe0e1e2e3e4e5e6e7e8e9eaebecedeeeff0f1f2f3f4f5f6f7f8f9fafbfcfdfeff byte))
)
