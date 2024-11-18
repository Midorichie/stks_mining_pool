;; Stacks Mining Pool Reward Distribution Contract
(define-constant contract-owner tx-sender)

;; Pool participants storage
(define-map pool-participants principal uint)

;; Track total pool rewards
(define-data-var total-pool-rewards uint u0)

;; Register as pool participant
(define-public (register-participant)
    (begin
        (map-set pool-participants tx-sender u100) ;; Initial stake
        (ok true)
    )
)

;; Distribute rewards based on participation
(define-public (distribute-rewards (total-reward uint))
    (begin
        ;; Ensure only contract owner can distribute
        (asserts! (is-eq tx-sender contract-owner) (err u403))
        
        ;; Update total pool rewards
        (var-set total-pool-rewards total-reward)
        
        (ok true)
    )
)

;; Claim individual rewards
(define-public (claim-reward)
    (let 
        (
            (participant-stake (default-to u0 (map-get? pool-participants tx-sender)))
            (total-rewards (var-get total-pool-rewards))
        )
        
        ;; Basic proportional reward calculation
        (if (> participant-stake u0)
            (begin
                (stx-transfer? 
                    (/ (* total-rewards participant-stake) u10000) 
                    contract-owner 
                    tx-sender
                )
                (ok true)
            )
            (err u404)
        )
    )
)