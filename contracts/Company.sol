// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

    
contract Company {
    
    // Company contract.
    // owners of the contract are the share holders of the company.

    
    address public master;
    // List to keep track of all owner's address
    address[] public owners;
    // Mapping to keep track of all owners of the company
    mapping(address => bool) isOwner;
    // Mapping to keep track of all balance of share holders of the company
    mapping(address => uint256) share;
    
    
    // Events
    event MasterSetup(address indexed master);
    event OwnerAddition(address indexed owner);
    event Transfer(address indexed receiver, uint256 amount);
    event OwnerRemoval(address indexed owner);
    
    
    modifier onlyMaster() {
        require(msg.sender == address(master), "Only Master has the right to call");
        _;
    }
    modifier onlyOwners() {
        require(isOwner[msg.sender], "Only owner can be added");
        _;
    }
    modifier onlyAdmins() {
        require(isOwner[msg.sender] || msg.sender == address(master), "Only master or owners");
        _;
    }
    
    /// @dev Constructor sets the master address of Company contract.
    /// @param _master address to setup master 
    constructor(address _master) {
        require(_master != address(0), "Master address cannot be a zero address");
        master = _master;
        share[master] = 10000000;
        emit MasterSetup(master);
    }
    
    /// @dev Returns the address of the master
    function getMaster()
        public
        view
        returns (address)
    {
        return master;
    }
    
    /// @dev Adds owner if the msg.sender is master. Will revert otherwise.
    /// @param owner Owner address to be added as owner.
    function addOwner(address owner) 
        onlyMaster 
        public
    {
        if(isOwner[owner] == true) return;
        isOwner[owner] = true;
        owners.push(owner);
        share[owner] = 5000000;
        
        emit OwnerAddition(owner);
    }
    
    /// @dev Returns the owner list of this Company contract.
    function getOwners()
        public
        view
        returns (address[] memory)
    {
        return owners;
    }
    
    /// @dev Returns whether the given address is owner or not.
    /// @param owner Address to check if is owner.
    function checkIfOwner(address owner)
        public
        view
        returns (bool)
    {
        return isOwner[owner];
    }

    /// @dev Transfers owner's or master's share to any address given.
    ///     Note: can only be called by one of the owners or master
    /// @param receiver Address of the receiver who'll receive the share
    /// @param _share Uint256 of the amount the admin wants to transfer
    function giveShare(address receiver, uint256 _share)
        public
        onlyAdmins
    {
        require(share[msg.sender] >= _share, "Stake exceeds the sender allowance");
        share[msg.sender] -= _share;
        share[receiver] += _share;
        
        emit Transfer(receiver, _share);
    }
    
    /// @dev Transfers owner's or master's stake(share) to an address in the owner list or master.
    ///     Note: the recipient can only be one of the owners
    /// @param receiver Address of the receipient
    /// @param _share Uint256 amount of the stake(share) to transfer
    function addShare(address receiver, uint256 _share)
        public
        onlyAdmins
    {
        require(share[msg.sender] >= _share, "Stake exceeds the sender allowance");
        require(isOwner[receiver], "The receipient should only be one of the owners");
        share[msg.sender] -= _share;
        share[receiver] += _share;
        
        emit Transfer(receiver, _share);
    }
    
    /// @dev Removes an owner from the owner list. Can only be called by master. Will Revert otherwise
    /// @param owner Address of the owner to be removed
    function removeOwner(address owner)
        public
        onlyMaster
    {
        require(isOwner[owner], "Only owners can be removed from owner list");
        isOwner[owner] = false;
        for (uint i = 0; i < owners.length - 1; i++)
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        owners.pop();
        
        emit OwnerRemoval(owner);
    }

    /// @dev Returns the share of the given address.
    /// @param user Address of the user to get the share
    function getShare(address user)
        public
        view
        returns (uint256)
    {
        return share[user];
    }
}
