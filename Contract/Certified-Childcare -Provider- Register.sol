// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title CertifiedChildcareProviderRegister
 * @notice Registry that allows childcare providers to register and allows authorized
 * certifiers to approve or revoke certification.
 */
contract CertifiedChildcareProviderRegister {
    address public owner;

    struct Provider {
        string name;
        string certificationId;
        bool isCertified;
        uint256 registeredAt;
    }

    mapping(address => Provider) private providers;
    mapping(address => bool) public certifiers;

    // Events
    event ProviderRegistered(address indexed provider, string name, uint256 timestamp);
    event ProviderCertified(address indexed provider, string certificationId, address indexed certifier, uint256 timestamp);
    event ProviderDecertified(address indexed provider, address indexed certifier, uint256 timestamp);
    event CertifierUpdated(address indexed account, bool allowed, address indexed changedBy, uint256 timestamp);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier onlyCertifier() {
        require(certifiers[msg.sender] || msg.sender == owner, "Only certifier or owner");
        _;
    }

    constructor() {
        owner = msg.sender;
        certifiers[msg.sender] = true;
        emit CertifierUpdated(msg.sender, true, msg.sender, block.timestamp);
    }

    /**
     * @notice Register yourself as a childcare provider.
     */
    function registerProvider(string calldata _name, string calldata _certificationId) external {
        Provider storage p = providers[msg.sender];

        if (p.registeredAt == 0) {
            p.registeredAt = block.timestamp;
        }

        p.name = _name;
        p.certificationId = _certificationId;

        emit ProviderRegistered(msg.sender, _name, block.timestamp);
    }

    /**
     * @notice Certify a provider (only authorized certifiers).
     */
    function certifyProvider(address _provider, string calldata _certificationId) external onlyCertifier {
        Provider storage p = providers[_provider];
        require(p.registeredAt != 0, "Provider not registered");

        p.isCertified = true;
        p.certificationId = _certificationId;

        emit ProviderCertified(_provider, _certificationId, msg.sender, block.timestamp);
    }

    /**
     * @notice Revoke certification for a provider.
     */
    function decertifyProvider(address _provider) external onlyCertifier {
        Provider storage p = providers[_provider];
        require(p.registeredAt != 0, "Provider not registered");
        require(p.isCertified, "Provider not certified");

        p.isCertified = false;

        emit ProviderDecertified(_provider, msg.sender, block.timestamp);
    }

    /**
     * @notice Add or remove authorized certifiers.
     */
    function setCertifier(address _account, bool _allowed) external onlyOwner {
        certifiers[_account] = _allowed;
        emit CertifierUpdated(_account, _allowed, msg.sender, block.timestamp);
    }

    /**
     * @notice Get complete provider details.
     */
    function getProvider(address _provider)
        external
        view
        returns (
            string memory name,
            string memory certificationId,
            bool isCertified,
            uint256 registeredAt
        )
    {
        Provider storage p = providers[_provider];
        return (p.name, p.certificationId, p.isCertified, p.registeredAt);
    }

    /**
     * @notice Check if an address is registered.
     */
    function isRegistered(address _provider) external view returns (bool) {
        return providers[_provider].registeredAt != 0;
    }

    /**
     * @notice Transfer ownership of the contract.
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Invalid owner address");

        owner = _newOwner;
        certifiers[_newOwner] = true;

        emit CertifierUpdated(_newOwner, true, msg.sender, block.timestamp);
    }
}

