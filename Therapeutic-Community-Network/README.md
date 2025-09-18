# Therapeutic Community Network Smart Contract

A decentralized platform built on Stacks blockchain for managing health condition support groups, enabling secure and private therapeutic communities.

## Overview

The Therapeutic Community Network smart contract facilitates the creation and management of support groups for individuals with specific health conditions. It provides a secure, blockchain-based platform where users can:

- Create and join support groups for various health conditions
- Schedule and participate in therapeutic sessions
- Maintain privacy controls and member verification
- Track participation and build community reputation

## Features

### Core Functionality

- **Support Group Management**: Create public, private, or invite-only support groups
- **Member Profiles**: Secure user profiles with health conditions and privacy settings
- **Session Scheduling**: Facilitators can create and manage therapeutic sessions
- **Attendance Tracking**: Automated attendance and participation scoring
- **Invitation System**: Private group invitation management
- **Reputation System**: Community-based reputation scoring

### Privacy & Security

- **Multi-level Privacy**: Public, private, and invite-only group types
- **Role-based Access**: Different permissions for members, moderators, and facilitators
- **Secure Invitations**: Cryptographic invitation system for private groups
- **Data Sovereignty**: User-controlled profile and health information

## Smart Contract Structure

### Data Types

#### Support Groups
```clarity
{
  name: string-ascii 100,
  condition: string-ascii 50,
  description: string-ascii 500,
  facilitator: principal,
  max-members: uint,
  member-count: uint,
  created-at: uint,
  is-active: bool,
  privacy-level: uint
}
```

#### Member Profiles
```clarity
{
  display-name: string-ascii 50,
  conditions: list 5 string-ascii 30,
  bio: string-ascii 200,
  privacy-settings: uint,
  reputation-score: uint,
  total-sessions: uint,
  created-at: uint
}
```

#### Sessions
```clarity
{
  group-id: uint,
  title: string-ascii 100,
  description: string-ascii 300,
  facilitator: principal,
  scheduled-time: uint,
  duration: uint,
  max-participants: uint,
  participant-count: uint,
  session-type: uint,
  is-completed: bool
}
```

## Public Functions

### User Management

- `create-profile(display-name, conditions, bio)` - Create user profile
- `join-group(group-id)` - Join a support group
- `join-session(session-id)` - Register for a session

### Group Management

- `create-support-group(name, condition, description, max-members, privacy-level)` - Create new support group
- `send-invite(group-id, invitee)` - Send invitation to private group
- `deactivate-group(group-id)` - Deactivate a group (facilitator/admin only)

### Session Management

- `create-session(group-id, title, description, scheduled-time, duration, max-participants, session-type)` - Create therapeutic session
- `mark-attendance(session-id, participant, attended)` - Mark session attendance (facilitator only)
- `complete-session(session-id)` - Mark session as completed

### Administrative

- `set-platform-fee(new-fee)` - Update platform fee (owner only)

## Read-Only Functions

- `get-group-info(group-id)` - Retrieve group information
- `get-member-info(group-id, member)` - Get member details for specific group
- `get-session-info(session-id)` - Retrieve session information
- `get-member-profile(member)` - Get user profile
- `is-group-member(group-id, member)` - Check group membership
- `get-platform-fee()` - Get current platform fee

## Privacy Levels

1. **Public (1)**: Open to all users
2. **Private (2)**: Requires approval to join
3. **Invite-Only (3)**: Requires explicit invitation

## User Roles

1. **Member (1)**: Basic participation rights
2. **Moderator (2)**: Can create sessions and manage group activities
3. **Facilitator (3)**: Full group management permissions

## Session Types

1. **Discussion (1)**: Open discussion format
2. **Educational (2)**: Structured learning sessions
3. **Therapy (3)**: Therapeutic intervention sessions

## Error Codes

- `u100`: Owner only operation
- `u101`: Resource not found
- `u102`: Unauthorized access
- `u103`: Resource already exists
- `u104`: Invalid input parameters
- `u105`: Group/session at capacity
- `u106`: User not a member
- `u107`: Session already completed

## Deployment

### Prerequisites

- Stacks blockchain node
- Clarity CLI tools
- STX tokens for deployment fees

### Deployment Steps

1. Compile the contract:
```bash
clarinet check
```

2. Deploy to testnet:
```bash
clarinet deploy --network testnet
```

3. Deploy to mainnet:
```bash
clarinet deploy --network mainnet
```

## Usage Examples

### Creating a Support Group

```clarity
(contract-call? .therapeutic-community create-support-group 
  "Anxiety Support Circle" 
  "Anxiety" 
  "A safe space for individuals dealing with anxiety disorders"
  u20 
  u1)
```

### Joining a Group

```clarity
(contract-call? .therapeutic-community join-group u1)
```

### Creating a Session

```clarity
(contract-call? .therapeutic-community create-session 
  u1 
  "Coping Strategies Workshop" 
  "Learn practical anxiety management techniques"
  u1640995200 
  u90 
  u15 
  u2)
```

## Security Considerations

- All health information remains on-chain but is user-controlled
- Privacy settings allow users to control data visibility
- Role-based access ensures appropriate permissions
- Invitation system prevents unauthorized access to private groups

## License

This smart contract is released under the MIT License.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Submit a pull request with detailed description

## Support

For technical support or questions about the Therapeutic Community Network, please open an issue in the project repository.

---

**Disclaimer**: This smart contract is designed for community support purposes and should not replace professional medical advice or treatment.