# TeleMed Access Token (TMAT)

A decentralized telemedicine platform built on Stacks blockchain using Clarity smart contracts. This project aims to facilitate secure, transparent, and efficient telemedicine services through blockchain technology.

The TeleMed Access Token (TMAT) system enables:
- Token-based appointment booking
- Provider credential verification
- Automated payment distribution
- Secure appointment management
- Provider rating system

## Smart Contract Features

### Token Management
- Standard token operations (transfer)
- Balance tracking
- Appointment staking mechanism

### Provider Management
- Registration system for healthcare providers
- Credential verification by contract owner
- Rating system infrastructure
- Specialty tracking

### Appointment System
- Secure booking mechanism
- Token staking for appointments
- Automatic payment release upon completion
- Appointment state management

### Security Features
- Input validation for all operations
- Principal validation
- Amount validation to prevent overflow
- Timestamp validation
- Role-based access control
- Error handling with specific error codes

## Getting Started

### Prerequisites
- Clarinet installed
- Stacks blockchain development environment set up

### Installation
1. Clone the repository
```bash
git clone https://github.com/yourusername/clarity-telehealth-access.git
cd clarity-telehealth-access
```

2. Install dependencies
```bash
clarinet requirements
```

### Contract Deployment
Deploy the contract using Clarinet:
```bash
clarinet deploy
```

## Usage

### Provider Registration
```clarity
(contract-call? .med-access-token register-provider "Cardiology")
```

### Book Appointment
```clarity
(contract-call? .med-access-token book-appointment 
    'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7 
    u1640995200 
    u100)
```

### Complete Appointment
```clarity
(contract-call? .med-access-token complete-appointment u1)
```

## Error Codes

| Code | Description |
|------|-------------|
| u100 | Not authorized |
| u101 | Invalid amount |
| u102 | Provider not verified |
| u103 | Invalid recipient |
| u104 | Invalid provider |
| u105 | Invalid timestamp |
| u106 | Zero amount |
| u107 | Invalid specialty |

## Security Considerations

### Input Validation
- All inputs are validated before processing
- Timestamps are checked against block height
- Amounts are validated against overflow
- Principal addresses are verified

### Access Control
- Only contract owner can verify providers
- Only verified providers can receive appointments
- Only appointment provider can mark completion

## Testing

Run the test suite:
```bash
clarinet test
```

## Future Enhancements

- Dispute resolution system
- Multi-signature requirements for high-value transactions
- Enhanced rating system
- Emergency appointment handling
- Specialized token economics
- Integration with healthcare provider databases

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request