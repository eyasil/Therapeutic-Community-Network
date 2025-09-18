;; Therapeutic Community Network Smart Contract
;; A decentralized platform for health condition support groups

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-already-exists (err u103))
(define-constant err-invalid-input (err u104))
(define-constant err-group-full (err u105))
(define-constant err-not-member (err u106))
(define-constant err-session-closed (err u107))

;; Data Variables
(define-data-var next-group-id uint u1)
(define-data-var next-session-id uint u1)
(define-data-var platform-fee uint u1000000) ;; 1 STX in microSTX

;; Data Maps
(define-map support-groups 
  uint 
  {
    name: (string-ascii 100),
    condition: (string-ascii 50),
    description: (string-ascii 500),
    facilitator: principal,
    max-members: uint,
    member-count: uint,
    created-at: uint,
    is-active: bool,
    privacy-level: uint ;; 1=public, 2=private, 3=invite-only
  }
)

(define-map group-members 
  {group-id: uint, member: principal}
  {
    joined-at: uint,
    role: uint, ;; 1=member, 2=moderator, 3=facilitator
    participation-score: uint,
    is-active: bool
  }
)

(define-map group-sessions 
  uint 
  {
    group-id: uint,
    title: (string-ascii 100),
    description: (string-ascii 300),
    facilitator: principal,
    scheduled-time: uint,
    duration: uint, ;; in minutes
    max-participants: uint,
    participant-count: uint,
    session-type: uint, ;; 1=discussion, 2=educational, 3=therapy
    is-completed: bool
  }
)

(define-map session-participants 
  {session-id: uint, participant: principal}
  {
    joined-at: uint,
    attendance-status: uint, ;; 1=registered, 2=attended, 3=absent
    feedback-score: uint
  }
)

(define-map member-profiles 
  principal 
  {
    display-name: (string-ascii 50),
    conditions: (list 5 (string-ascii 30)),
    bio: (string-ascii 200),
    privacy-settings: uint,
    reputation-score: uint,
    total-sessions: uint,
    created-at: uint
  }
)

(define-map group-invites 
  {group-id: uint, invitee: principal}
  {
    inviter: principal,
    invited-at: uint,
    status: uint ;; 1=pending, 2=accepted, 3=declined
  }
)

;; Read-only functions
(define-read-only (get-group-info (group-id uint))
  (map-get? support-groups group-id)
)

(define-read-only (get-member-info (group-id uint) (member principal))
  (map-get? group-members {group-id: group-id, member: member})
)

(define-read-only (get-session-info (session-id uint))
  (map-get? group-sessions session-id)
)

(define-read-only (get-member-profile (member principal))
  (map-get? member-profiles member)
)

(define-read-only (is-group-member (group-id uint) (member principal))
  (is-some (map-get? group-members {group-id: group-id, member: member}))
)

(define-read-only (get-next-group-id)
  (var-get next-group-id)
)

(define-read-only (get-next-session-id)
  (var-get next-session-id)
)

(define-read-only (get-platform-fee)
  (var-get platform-fee)
)

;; Public functions

;; Create member profile
(define-public (create-profile (display-name (string-ascii 50)) 
                              (conditions (list 5 (string-ascii 30))) 
                              (bio (string-ascii 200)))
  (let ((existing-profile (map-get? member-profiles tx-sender)))
    (asserts! (is-none existing-profile) err-already-exists)
    (asserts! (> (len display-name) u0) err-invalid-input)
    (map-set member-profiles tx-sender {
      display-name: display-name,
      conditions: conditions,
      bio: bio,
      privacy-settings: u1,
      reputation-score: u0,
      total-sessions: u0,
      created-at: block-height
    })
    (ok true)
  )
)

;; Create support group
(define-public (create-support-group (name (string-ascii 100)) 
                                   (condition (string-ascii 50)) 
                                   (description (string-ascii 500))
                                   (max-members uint)
                                   (privacy-level uint))
  (let ((group-id (var-get next-group-id)))
    (asserts! (> (len name) u0) err-invalid-input)
    (asserts! (> (len condition) u0) err-invalid-input)
    (asserts! (> max-members u0) err-invalid-input)
    (asserts! (and (>= privacy-level u1) (<= privacy-level u3)) err-invalid-input)
    
    ;; Create group
    (map-set support-groups group-id {
      name: name,
      condition: condition,
      description: description,
      facilitator: tx-sender,
      max-members: max-members,
      member-count: u1,
      created-at: block-height,
      is-active: true,
      privacy-level: privacy-level
    })
    
    ;; Add creator as facilitator
    (map-set group-members {group-id: group-id, member: tx-sender} {
      joined-at: block-height,
      role: u3, ;; facilitator
      participation-score: u0,
      is-active: true
    })
    
    (var-set next-group-id (+ group-id u1))
    (ok group-id)
  )
)

;; Join support group
(define-public (join-group (group-id uint))
  (let ((group-info (unwrap! (map-get? support-groups group-id) err-not-found))
        (existing-member (map-get? group-members {group-id: group-id, member: tx-sender})))
    
    (asserts! (is-none existing-member) err-already-exists)
    (asserts! (get is-active group-info) err-not-found)
    (asserts! (< (get member-count group-info) (get max-members group-info)) err-group-full)
    
    ;; For private/invite-only groups, check invite
    (if (> (get privacy-level group-info) u1)
      (let ((invite (map-get? group-invites {group-id: group-id, invitee: tx-sender})))
        (asserts! (is-some invite) err-unauthorized)
        (asserts! (is-eq (get status (unwrap-panic invite)) u1) err-unauthorized)
        ;; Accept the invite
        (map-set group-invites {group-id: group-id, invitee: tx-sender}
          (merge (unwrap-panic invite) {status: u2}))
      )
      true
    )
    
    ;; Add member
    (map-set group-members {group-id: group-id, member: tx-sender} {
      joined-at: block-height,
      role: u1, ;; regular member
      participation-score: u0,
      is-active: true
    })
    
    ;; Update member count
    (map-set support-groups group-id 
      (merge group-info {member-count: (+ (get member-count group-info) u1)}))
    
    (ok true)
  )
)

;; Create session
(define-public (create-session (group-id uint) 
                              (title (string-ascii 100)) 
                              (description (string-ascii 300))
                              (scheduled-time uint)
                              (duration uint)
                              (max-participants uint)
                              (session-type uint))
  (let ((session-id (var-get next-session-id))
        (group-info (unwrap! (map-get? support-groups group-id) err-not-found))
        (member-info (unwrap! (map-get? group-members {group-id: group-id, member: tx-sender}) err-not-member)))
    
    (asserts! (get is-active group-info) err-not-found)
    (asserts! (>= (get role member-info) u2) err-unauthorized) ;; moderator or facilitator only
    (asserts! (> (len title) u0) err-invalid-input)
    (asserts! (> duration u0) err-invalid-input)
    (asserts! (and (>= session-type u1) (<= session-type u3)) err-invalid-input)
    
    (map-set group-sessions session-id {
      group-id: group-id,
      title: title,
      description: description,
      facilitator: tx-sender,
      scheduled-time: scheduled-time,
      duration: duration,
      max-participants: max-participants,
      participant-count: u0,
      session-type: session-type,
      is-completed: false
    })
    
    (var-set next-session-id (+ session-id u1))
    (ok session-id)
  )
)

;; Join session
(define-public (join-session (session-id uint))
  (let ((session-info (unwrap! (map-get? group-sessions session-id) err-not-found))
        (group-id (get group-id session-info))
        (member-info (unwrap! (map-get? group-members {group-id: group-id, member: tx-sender}) err-not-member))
        (existing-participant (map-get? session-participants {session-id: session-id, participant: tx-sender})))
    
    (asserts! (is-none existing-participant) err-already-exists)
    (asserts! (not (get is-completed session-info)) err-session-closed)
    (asserts! (get is-active member-info) err-unauthorized)
    (asserts! (< (get participant-count session-info) (get max-participants session-info)) err-group-full)
    
    ;; Add participant
    (map-set session-participants {session-id: session-id, participant: tx-sender} {
      joined-at: block-height,
      attendance-status: u1, ;; registered
      feedback-score: u0
    })
    
    ;; Update participant count
    (map-set group-sessions session-id 
      (merge session-info {participant-count: (+ (get participant-count session-info) u1)}))
    
    (ok true)
  )
)

;; Mark attendance
(define-public (mark-attendance (session-id uint) (participant principal) (attended bool))
  (let ((session-info (unwrap! (map-get? group-sessions session-id) err-not-found))
        (group-id (get group-id session-info))
        (facilitator-info (unwrap! (map-get? group-members {group-id: group-id, member: tx-sender}) err-not-member))
        (participant-info (unwrap! (map-get? session-participants {session-id: session-id, participant: participant}) err-not-found)))
    
    (asserts! (>= (get role facilitator-info) u2) err-unauthorized) ;; moderator or facilitator only
    
    (map-set session-participants {session-id: session-id, participant: participant}
      (merge participant-info {attendance-status: (if attended u2 u3)}))
    
    ;; Update member's total sessions if attended
    (if attended
      (let ((member-profile (unwrap! (map-get? member-profiles participant) err-not-found)))
        (map-set member-profiles participant
          (merge member-profile {total-sessions: (+ (get total-sessions member-profile) u1)}))
      )
      true
    )
    
    (ok true)
  )
)

;; Complete session
(define-public (complete-session (session-id uint))
  (let ((session-info (unwrap! (map-get? group-sessions session-id) err-not-found)))
    (asserts! (is-eq tx-sender (get facilitator session-info)) err-unauthorized)
    (asserts! (not (get is-completed session-info)) err-session-closed)
    
    (map-set group-sessions session-id (merge session-info {is-completed: true}))
    (ok true)
  )
)

;; Send group invite (for private groups)
(define-public (send-invite (group-id uint) (invitee principal))
  (let ((group-info (unwrap! (map-get? support-groups group-id) err-not-found))
        (member-info (unwrap! (map-get? group-members {group-id: group-id, member: tx-sender}) err-not-member))
        (existing-invite (map-get? group-invites {group-id: group-id, invitee: invitee})))
    
    (asserts! (get is-active group-info) err-not-found)
    (asserts! (>= (get role member-info) u2) err-unauthorized) ;; moderator or facilitator only
    (asserts! (> (get privacy-level group-info) u1) err-invalid-input) ;; only for private groups
    (asserts! (is-none existing-invite) err-already-exists)
    
    (map-set group-invites {group-id: group-id, invitee: invitee} {
      inviter: tx-sender,
      invited-at: block-height,
      status: u1 ;; pending
    })
    
    (ok true)
  )
)

;; Admin functions
(define-public (set-platform-fee (new-fee uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set platform-fee new-fee)
    (ok true)
  )
)

(define-public (deactivate-group (group-id uint))
  (let ((group-info (unwrap! (map-get? support-groups group-id) err-not-found)))
    (asserts! (or (is-eq tx-sender contract-owner) 
                  (is-eq tx-sender (get facilitator group-info))) err-unauthorized)
    
    (map-set support-groups group-id (merge group-info {is-active: false}))
    (ok true)
  )
)