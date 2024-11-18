;; Enhanced Stacks Mining Pool Reward Distribution Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant min-stake u100)
(define-constant max-stake u10000)
(define-constant base-reward-percentage u20)

;; Storage for pool participants
(define-map pool-participants 
    {
        participant: principal,
        status: (string-ascii 20)
    } 
    {
        total-stake: uint,
        last-reward-claimed: uint,
        total-rewards-earned: uint
    }
)

;; Global pool statistics
(define-data-var total-pool-stake uint u0)
(define-data-var total-pool-rewards uint u0)
(define-data-var reward-epoch uint u0)

;; Register as pool participant with initial stake
(define-public (register-participant (stake uint))
    (begin
        ;; Validate stake amount
        (asserts! (and (>= stake min-stake) (<= stake max-stake)) (err u403))
        
        ;; Transfer stake to contract
        (try! (stx-transfer? stake tx-sender (as-contract tx-sender)))
        
        ;; Update participant record
        (map-set pool-participants 
            {
                participant: tx-sender, 
                status: "active"
            }
            {
                total-stake: stake,
                last-reward-claimed: (var-get reward-epoch),
                total-rewards-earned: u0
            }
        )
        
        ;; Update total pool stake
        (var-set total-pool-stake (+ (var-get total-pool-stake) stake))
        
        (ok true)
    )
)

;; Distribute rewards proportionally
(define-public (distribute-pool-rewards (total-reward uint))
    (begin
        ;; Ensure only contract owner can distribute
        (asserts! (is-eq tx-sender contract-owner) (err u403))
        
        ;; Increment reward epoch
        (var-set reward-epoch (+ (var-get reward-epoch) u1))
        
        ;; Update total pool rewards
        (var-set total-pool-rewards total-reward)
        
        (ok true)
    )
)

;; Advanced reward claiming mechanism
(define-public (claim-proportional-reward)
    (let 
        (
            (participant-data 
                (unwrap! 
                    (map-get? pool-participants 
                        {
                            participant: tx-sender, 
                            status: "active"
                        }
                    ) 
                    (err u404)
                )
            )
            (total-rewards (var-get total-pool-rewards))
            (participant-stake (get total-stake participant-data))
            (last-claimed-epoch (get last-reward-claimed participant-data))
        )
        
        ;; Complex reward calculation
        (let 
            (
                (reward-percentage 
                    (/ 
                        (* participant-stake base-reward-percentage) 
                        (var-get total-pool-stake)
                    )
                )
                (participant-reward 
                    (/ 
                        (* total-rewards reward-percentage) 
                        u100
                    )
                )
            )
            
            ;; Update participant record
            (map-set pool-participants 
                {
                    participant: tx-sender, 
                    status: "active"
                }
                {
                    total-stake: participant-stake,
                    last-reward-claimed: (var-get reward-epoch),
                    total-rewards-earned: (+ 
                        (get total-rewards-earned participant-data) 
                        participant-reward
                    )
                }
            )
            
            ;; Transfer reward
            (try! 
                (stx-transfer? 
                    participant-reward 
                    (as-contract tx-sender) 
                    tx-sender
                )
            )
            
            (ok participant-reward)
        )
    )
)