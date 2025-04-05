// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SelfVerificationRoot } from "@selfxyz/contracts/contracts/abstract/SelfVerificationRoot.sol";
import { CircuitConstants } from "@selfxyz/contracts/contracts/constants/CircuitConstants.sol";
import { IIdentityVerificationHubV1 } from "@selfxyz/contracts/contracts/interfaces/IIdentityVerificationHubV1.sol";
import { IVcAndDiscloseCircuitVerifier } from
    "@selfxyz/contracts/contracts/interfaces/IVcAndDiscloseCircuitVerifier.sol";

contract Post is SelfVerificationRoot, ERC20 {
    address public immutable relayer;

    // restriction variable
    string public gender;
    string public nationality;

    mapping(uint256 => bool) private _nullifiers;

    error RegisteredNullifier();
    error InvalidMsgSender(address msgSender);
    error InvalidGender(string gender);
    error InvalidNationality(string nationality);
    error InvalidAge(uint256 age);

    modifier onlyRelayer() {
        require(msg.sender == relayer, InvalidMsgSender(msg.sender));
        _;
    }

    constructor(
        address _identityVerificationHub,
        uint256 _scope,
        uint256 _attestationId,
        bool _olderThanEnabled,
        uint256 _olderThan,
        bool _forbiddenCountriesEnabled,
        uint256[4] memory _forbiddenCountriesListPacked,
        bool[3] memory _ofacEnabled,
        address _relayer,
        string memory _name,
        string memory _symbol,
        string memory _gender,
        string memory _nationality
    )
        SelfVerificationRoot(
            _identityVerificationHub, // Address of our Verification Hub, e.g., "0x77117D60eaB7C044e785D68edB6C7E0e134970Ea"
            _scope, // An application-specific identifier for the integrated contract
            _attestationId, // The id specifying the type of document to verify (e.g., 1 for passports)
            _olderThanEnabled, // Flag to enable age verification
            _olderThan, // The minimum age required for verification
            _forbiddenCountriesEnabled, // Flag to enable forbidden countries verification
            _forbiddenCountriesListPacked, // Packed data representing the list of forbidden countries
            _ofacEnabled // Flag to enable OFAC check
        )
        ERC20(_name, _symbol)
    {
        relayer = _relayer;
        gender = _gender;
        nationality = _nationality;
    }

    function verifySelfProof(IVcAndDiscloseCircuitVerifier.VcAndDiscloseProof memory proof, uint256 age)
        public
        onlyRelayer
    {
        if (_scope != proof.pubSignals[CircuitConstants.VC_AND_DISCLOSE_SCOPE_INDEX]) {
            revert InvalidScope();
        }

        if (_attestationId != proof.pubSignals[CircuitConstants.VC_AND_DISCLOSE_ATTESTATION_ID_INDEX]) {
            revert InvalidAttestationId();
        }

        if (_nullifiers[proof.pubSignals[CircuitConstants.VC_AND_DISCLOSE_NULLIFIER_INDEX]]) {
            revert RegisteredNullifier();
        }

        IIdentityVerificationHubV1.VcAndDiscloseVerificationResult memory result = _identityVerificationHub
            .verifyVcAndDisclose(
            IIdentityVerificationHubV1.VcAndDiscloseHubProof({
                olderThanEnabled: _verificationConfig.olderThanEnabled,
                olderThan: _verificationConfig.olderThan,
                forbiddenCountriesEnabled: _verificationConfig.forbiddenCountriesEnabled,
                forbiddenCountriesListPacked: _verificationConfig.forbiddenCountriesListPacked,
                ofacEnabled: _verificationConfig.ofacEnabled,
                vcAndDiscloseProof: proof
            })
        );

        if (_isValidCommenter(result.revealedDataPacked, age)) {
            _nullifiers[result.nullifier] = true;
        }
    }

    function sendRewardToken(address commenter) external onlyRelayer {
        _mint(commenter, 1 ether);
    }

    function _isValidCommenter(uint256[3] memory _revealedDataPacked, uint256 age) private view returns (bool) {
        IIdentityVerificationHubV1.RevealedDataType[] memory types =
            new IIdentityVerificationHubV1.RevealedDataType[](3);
        types[0] = IIdentityVerificationHubV1.RevealedDataType.NATIONALITY;
        types[1] = IIdentityVerificationHubV1.RevealedDataType.GENDER;
        types[2] = IIdentityVerificationHubV1.RevealedDataType.OLDER_THAN;

        IIdentityVerificationHubV1.ReadableRevealedData memory revealedData =
            IIdentityVerificationHubV1(_identityVerificationHub).getReadableRevealedData(_revealedDataPacked, types);

        if (keccak256(abi.encodePacked(revealedData.gender)) != keccak256(abi.encodePacked(gender))) {
            revert InvalidGender(revealedData.gender);
        } else if (keccak256(abi.encodePacked(revealedData.nationality)) != keccak256(abi.encodePacked(nationality))) {
            revert InvalidNationality(revealedData.nationality);
        } else if (age < _verificationConfig.olderThan) {
            revert InvalidAge(age);
        } else {
            return true;
        }
    }
}
