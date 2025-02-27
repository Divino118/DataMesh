;; DataMesh Decentralized Storage System - AlphaX
;; Version X.1 - Optimized Sharding & High-Speed Queries
;; Refactored for improved readability and expanded functionality

;; System Constants
(define-constant SYSTEM_ADMIN tx-sender)
(define-constant ERROR_UNAUTHORIZED (err u200))
(define-constant ERROR_INVALID_PARAMS (err u201))
(define-constant ERROR_INSUFFICIENT_COLLATERAL (err u202))
(define-constant ERROR_INVALID_SHARD (err u203))
(define-constant ERROR_NODE_NOT_FOUND (err u204))
(define-constant ERROR_SYSTEM_INACTIVE (err u205))
(define-constant ERROR_CAPACITY_EXCEEDED (err u206))
(define-constant MINIMUM_STAKE_REQUIREMENT u5000)
(define-constant MAX_EFFICIENCY_RATING u100)
(define-constant DEFAULT_TIMEOUT_LIMIT u1000)

;; Global State Variables
(define-data-var system-status bool true)
(define-data-var total-shards uint u0)
(define-data-var total-nodes uint u0)
(define-data-var system-version (string-ascii 16) "X.1.0")
(define-data-var last-maintenance-block uint u0)

;; Default Collections
(define-data-var default-uint-list (list 10 uint) (list ))
(define-data-var default-string-list (list 5 (string-ascii 32)) (list ))
(define-data-var default-node-list (list 3 uint) (list ))

;; Node Registry Structure
(define-map StorageNodes
    { node-id: uint }
    {
        node-type: (string-ascii 64),
        online-start: uint,
        online-end: uint,
        store-location: (string-ascii 256),
        service-url: (string-ascii 256),
        staked-amount: uint,
        active-status: bool,
        performance-score: uint,
        assigned-shards: (list 10 uint)
    }
)

;; Shard Registry Structure
(define-map StorageShards
    { shard-id: uint }
    {
        max-size: uint,
        connected-nodes: (list 3 uint),
        shard-type: (string-ascii 64),
        key-start: uint,
        key-end: uint,
        locked-status: bool
    }
)

;; Storage Configuration
(define-map StorageConfig
    { config-id: uint }
    {
        max-shard-size: uint,
        replication-factor: uint,
        enable-compression: bool,
        distribution-strategy: (string-ascii 32),
        required-consistency: uint
    }
)

;; Query Configuration
(define-map QueryConfig
    { query-id: uint }
    {
        target-node: uint,
        allowed-operations: (list 5 (string-ascii 32)),
        max-complexity: uint,
        timeout-limit: uint
    }
)

;; Performance Metrics
(define-map NodeMetrics
    { node-id: uint }
    {
        total-uptime: uint,
        successful-queries: uint,
        failed-queries: uint,
        data-transferred: uint,
        response-time-avg: uint
    }
)

;; Shard Management Functions
(define-public (create-shard 
    (shard-id uint)
    (shard-type (string-ascii 64))
    (key-start uint)
    (key-end uint))
    (let
        (
            (empty-nodes (var-get default-node-list))
        )
        (begin
            (asserts! (is-eq tx-sender SYSTEM_ADMIN) ERROR_UNAUTHORIZED)
            (asserts! (var-get system-status) ERROR_SYSTEM_INACTIVE)
            (asserts! (valid-range key-start key-end) ERROR_INVALID_PARAMS)
            (asserts! (is-none (get-shard-info shard-id)) ERROR_INVALID_SHARD)
            
            (map-set StorageShards
                { shard-id: shard-id }
                {
                    max-size: u0,
                    connected-nodes: empty-nodes,
                    shard-type: shard-type,
                    key-start: key-start,
                    key-end: key-end,
                    locked-status: false
                }
            )
            (var-set total-shards (+ (var-get total-shards) u1))
            (ok true)
        )
    )
)

;; Node Registration Functions
(define-public (register-node 
    (node-id uint) 
    (node-type (string-ascii 64))
    (online-start uint)
    (online-end uint)
    (store-location (string-ascii 256))
    (service-url (string-ascii 256))
    (staked-amount uint))
    (begin
        (asserts! (var-get system-status) ERROR_SYSTEM_INACTIVE)
        (asserts! (>= staked-amount MINIMUM_STAKE_REQUIREMENT) ERROR_INSUFFICIENT_COLLATERAL)
        (asserts! (valid-range online-start online-end) ERROR_INVALID_PARAMS)
        (asserts! (is-none (get-node-info node-id)) ERROR_INVALID_PARAMS)
        
        (map-set StorageNodes
            { node-id: node-id }
            {
                node-type: node-type,
                online-start: online-start,
                online-end: online-end,
                store-location: store-location,
                service-url: service-url,
                staked-amount: staked-amount,
                active-status: true,
                performance-score: MAX_EFFICIENCY_RATING,
                assigned-shards: (var-get default-uint-list)
            }
        )
        
        ;; Initialize metrics for the new node
        (map-set NodeMetrics
            { node-id: node-id }
            {
                total-uptime: u0,
                successful-queries: u0,
                failed-queries: u0,
                data-transferred: u0,
                response-time-avg: u0
            }
        )
        
        (var-set total-nodes (+ (var-get total-nodes) u1))
        (ok true)
    )
)

;; Query Management Functions
(define-public (configure-query 
    (query-id uint)
    (target-node uint)
    (max-complexity uint)
    (timeout-limit uint))
    (begin
        (asserts! (is-eq tx-sender SYSTEM_ADMIN) ERROR_UNAUTHORIZED)
        (asserts! (var-get system-status) ERROR_SYSTEM_INACTIVE)
        (asserts! (node-exists target-node) ERROR_NODE_NOT_FOUND)
        
        (map-set QueryConfig
            { query-id: query-id }
            {
                target-node: target-node,
                allowed-operations: (var-get default-string-list),
                max-complexity: max-complexity,
                timeout-limit: (if (> timeout-limit u0) timeout-limit DEFAULT_TIMEOUT_LIMIT)
            }
        )
        (ok true)
    )
)

;; Storage Configuration Functions
(define-public (configure-storage
    (config-id uint)
    (max-shard-size uint)
    (replication-factor uint)
    (enable-compression bool)
    (distribution-strategy (string-ascii 32))
    (required-consistency uint))
    (begin
        (asserts! (is-eq tx-sender SYSTEM_ADMIN) ERROR_UNAUTHORIZED)
        (asserts! (var-get system-status) ERROR_SYSTEM_INACTIVE)
        (asserts! (valid-storage-config max-shard-size replication-factor required-consistency) ERROR_INVALID_PARAMS)
        
        (map-set StorageConfig
            { config-id: config-id }
            {
                max-shard-size: max-shard-size,
                replication-factor: replication-factor,
                enable-compression: enable-compression,
                distribution-strategy: distribution-strategy,
                required-consistency: required-consistency
            }
        )
        (ok true)
    )
)

;; System Management Functions
(define-public (toggle-system-status (new-status bool))
    (begin
        (asserts! (is-eq tx-sender SYSTEM_ADMIN) ERROR_UNAUTHORIZED)
        (var-set system-status new-status)
        (var-set last-maintenance-block stacks-block-height)
        (ok true)
    )
)

;; Helper Functions
(define-private (valid-range (start uint) (end uint))
    (and (> end start) (> start u0))
)

(define-private (node-exists (node-id uint))
    (is-some (get-node-info node-id))
)

(define-private (valid-storage-config (max-size uint) (replication uint) (consistency uint))
    (and 
        (> max-size u0)
        (>= replication u1)
        (<= consistency replication)
    )
)

;; Read-Only Functions
(define-read-only (get-shard-info (shard-id uint))
    (map-get? StorageShards { shard-id: shard-id })
)

(define-read-only (get-node-info (node-id uint))
    (map-get? StorageNodes { node-id: node-id })
)

(define-read-only (get-query-config (query-id uint))
    (map-get? QueryConfig { query-id: query-id })
)

(define-read-only (get-system-info)
    {
        status: (var-get system-status),
        version: (var-get system-version),
        total-shards: (var-get total-shards),
        total-nodes: (var-get total-nodes),
        last-maintenance: (var-get last-maintenance-block)
    }
)

(define-read-only (get-node-metrics (node-id uint))
    (map-get? NodeMetrics { node-id: node-id })
)