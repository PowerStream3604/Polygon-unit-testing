# Polygon Smart Contract unit testing with truffle

## Introduction
In this tutorial, you will learn how to deploy & unit test smart contracts in solidity using truffle. Before diving into unit testing we will implement a Smart-Contract for testing. Grab a cup of tea and review the Smart-Contract and unit test them!

## Prerequisites
This tutorial assumes that you have understanding of solidity, truffle, and blockchain.

## Requirements
- [Truffle](https://www.trufflesuite.com/)
- [Solidity](https://docs.soliditylang.org/en/v0.8.9/)

## Getting Started

### What is unit testing?
Unit testing is a way of **testing a unit** - the smallest piece of code that can be logically isolated in a system. These units are mostly functions, subroutine, methods or property.

### Introduction about the Smart Contract we'll implement.
Before actually testing the Smart Contracts, lets first implement a Smart Contract to test.

The smart contract we'll implement is a Smart Contract that represents a **Corportion**. Similar to how corporations behave, the Smart Contract have a **role** of 
**Owners :** shareholders of the company who have limited access.
**Master :** the president of the company with full access.
**Admins :** both **Owners** and **Master** together as a group.

#### Features :
1. **Master** has the right to **add** owner with **addOwner()** and **remove** owner with **removeOwner()**.
2. **Admins**(owner & master) have the right to transfer their share to anyone using the **giveShare()** function.
3. **Admins**(owner & master) have the right to transfer their share to one of the owners(not master) using the **addShare()** function.
4. **checkIfOwner()** returns whether the given address is owner or not.
5. **getMaster()** returns the address of the **master**
6. **getOwners()** returns the list of **owner** addresses
7. **Users** who are not in the boundary of **admins** cannot transfer their share but can just **receive**.


#### Events :
1. **MasterSetup** is emitted when **Master** is set
```solidity
event MasterSetup(address indexed master);
```

2. **OwnerAddition** is emitted when **Owner** is added by **Master**
```solidity
event OwnerAddition(address indexed owner);
```

3. **OwnerRemoval** is emitted when **Owner** is removed by **Master**
```solidity
event OwnerRemoval(address indexed owner);
```

4. **Transfer** is emitted when share of admins gets transfer by either of these functions **addShare()**, **giveShare()**
```solidity
event Transfer(address indexed receiver, uint256 amount);
```

### Deep Dive into programming Smart Contracts

*Notes: We name this smart Contract as **Company** and use solidity version **0.8.7***

Before defining the events and functions, let's first define variables to be used in the Smart Contract.

```solidity
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
    
}
```

After defining the variables, we should define events to be used in the Company Smart Contract.

```solidity
// Events
event MasterSetup(address indexed master);
event OwnerAddition(address indexed owner);
event Transfer(address indexed receiver, uint256 amount);
event OwnerRemoval(address indexed owner);
```

Since we defined the events, we should define modifier to limit access from **anonymous** or **unauthorized** users.

```solidity
modifier onlyMaster() {
    require(msg.sender == address(master));
    _;
}
modifier onlyOwners() {
    require(isOwner[msg.sender], "Only owners have the right to call");
    _;
}
modifier onlyAdmins() {
    require(isOwner[msg.sender] || msg.sender == address(master), "Only master or owners have the right to call");
    _;
}
```

We should define the constructor to set the address of the **Master**.

```solidity
/// @dev Constructor sets the master address of Company contract.
/// @param _master address to setup master 
constructor(address _master) {
    require(_master != address(0), "Master address cannot be a zero address");
    master = _master;
    share[master] = 10000000;
    emit MasterSetup(master);
}
```

Also, we should define functions to get the information about **Master** and **Owners**.

```solidity
/// @dev Returns the address of the master
function getMaster()
    public
    view
    returns (address)
{
    return master;
}

/// @dev Returns the owner list of this Company contract.
function getOwners()
    public
    view
    returns (address[] memory)
{
    return owners;
}
```

We would need a function to check if the given address is owner or not.

```solidity
/// @dev Returns whether the given address is owner or not.
/// @param owner Address to check if is owner.
function checkIfOwner(address owner)
    public
    view
    returns (bool)
{
    return isOwner[owner];
}
```

We would also need functions to **add** and **remove** owners.

```solidity
/// @dev Adds owner if the msg.sender is master. Will revert otherwise.
/// @param owner Owner address to be added as owner.
function addOwner(address owner) 
    onlyMaster 
    public
{
    isOwner[owner] = true;
    owners.push(owner);
    share[owner] = 5000000;
    
    emit OwnerAddition(owner);
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
```

The most important part of all, we need functions to transfer share.

```solidity
/// @dev Transfers owner's or master's share to any address given.
///     Note: can only be called by one of the owners or master
/// @param receiver Address of the receiver who'll receive the share
/// @param _share Uint256 of the amount the admin wants to transfer
function giveShare(address receiver, uint256 _share)
    public
    onlyAdmins
{
    require(share[msg.sender] >= _share, "Share exceeds the sender allowance");
    share[msg.sender] = share[msg.sender] - _share;
    share[receiver] += _share;
        
    emit Transfer(receiver, _share);
}
    
/// @dev Transfers owner's or master's stake(share) to an address in the owner list or master.
///     Note: the recipient can only be one of the admins(owner or master)
/// @param receiver Address of the receipient
/// @param _share Uint256 amount of the stake(share) to transfer
function addShare(address receiver, uint256 _share)
    public
    onlyAdmins
{
    require(share[msg.sender] >= _share, "Share exceeds the sender allowance");
    require(isOwner[receiver], "The receipient should only be one of the owners");
    share[msg.sender] -= _share;
    share[receiver] += _share;
        
    emit Transfer(receiver, _share);
}
```

Here is the full **implementation**.
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

    
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
        require(msg.sender == address(master));
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
        share[msg.sender] = share[msg.sender] - _share;
        share[receiver] += _share;
        
        emit Transfer(receiver, _share);
    }
    
    /// @dev Transfers owner's or master's stake(share) to an address in the owner list or master.
    ///     Note: the recipient can only be one of the admins(owner or master)
    /// @param receiver Address of the receipient
    /// @param _share Uint256 amount of the stake(share) to transfer
    function addShare(address receiver, uint256 _share)
        public
        onlyAdmins
    {
        require(share[msg.sender] >= _share, "Share exceeds the sender allowance");
        require(isOwner[receiver], "The receipient should only be one of the owners");
        share[msg.sender] = share[msg.sender] - _share;
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
}
```

**Hooray!!** We implemented the whole contract!!

Let's then go to unit test the above contract with Truffle.

## Unit Testing With Truffle

As I mentioned above, unit testing is testing the **smallest** unit which can be functions, subroutines, methods, etc.
Truffle provides a convinient library to test smart contracts, by using **truffle-assert** library, we'll check if all scenarios stand by our expectation.

#### Downloading Truffle

[Truffle](https://www.trufflesuite.com/)

Write the command below to install truffle.

```bash
$ cd polygon_unitTest
$ npm install truffle
```

#### Initialize truffle project

```bash
$ truffle init
```
Then, you'll see a project directory like this.

![project overview](https://i.ibb.co/19Xnw0X/Screen-Shot-2021-10-22-at-9-52-29-AM.png)

#### Paste your smart contract into the contracts folder

Create Company.sol file to paste in the smart contract.

```bash
$ touch Company.sol
```

**Then**, paste the smart contract.

#### Configure the network settings

```bash
$ vi truffle-config.js
```

Inside the **networks** object paste the below network configuration.

```bash
mumbai: {
      provider: () => new HDWalletProvider(["<Private Key 1>", "<Private Key 2>", "<Private Key 3>"],
      "https://polygon-mumbai.infura.io/v3/[PROJECT-ID]"),
      network_id: 80001,
      confirmations: 2,
      timeoutBlocks: 200,
      skipDryRun: true,
      networkCheckTimeout: 100000,
}
```

the above configuration sets the provider url to connect truffle with the node of **mumbai chain**, and provides private keys to **sign** and pay for **gas fee** on **mumbai**.

*NOTES : The private key of the accounts should be funded with **MATIC** on Mumbai.*

#### Create company.js file in test folder

In order to create test in truffle, create a test file under the **test** folder.

```bash
$ cd test
$ touch company.js
```

#### Create deployment file to deploy Company Contract

```bash
$ cd migrations
$ touch 2_deploy_contract.js
```

To deploy contract in the connected network. Add the following line.

```javascript
const Company = artifacts.require("Company");

module.exports = function (deployer, networks, accounts) {
    deployer.deploy(Company, account);
};
```

#### Before unit testing smart contract
We'll use the javascript library of truffle to test the functions.

Before going in, we'll import the contract we'll test and the truffle library for testing.

```javascript
const Company = artifacts.require("Company");
const truffleAssert = require('truffle-assertions');
```

Also, we'll define user variable to better distinguish accounts for testing we designated in the **truffle-config.js** file.

```javascript
const user1 = accounts[0];
const user2 = accounts[1];
const user3 = accounts[2];
```
#### Deep dive into unit testing

1. Test if the Master address is set appropariately by the constructor.
```javascript
it("1. should be able to set the right master", async () => {
    // Get deployed contract
    const company = await Company.deployed();
    // Check if the master address equals to user1
    assert.deepEqual(await company.getMaster(), user1);
});
```

2. Check if only master is able to add owner
```javascript
it("2. only master should be able to add owner", async () => {
    // Get deployed contract
    const company = await Company.deployed();
    // Check if the user2(is not master) get reverted when attempting to add owner
    await truffleAssert.reverts(
        company.addOwner(user1, {from: user2}),
    );
});
```

3. Check if Master is able to add owner.
```javascript
it("3. master should be able to add owner", async() => {
    // Get deployed contract
    const company = await Company.deployed();
    // call addOwner(); {from: accounts[0]} is added as default(who is master)
    const tx = await company.addOwner(user1);
    // Check if OwnerAddition is getting emitted
    truffleAssert.eventEmitted(tx, "OwnerAddition", (ev) => {
        return ev.owner == user1;
    })
    // Check if getOwners() returns the ownerList with user1 as owner inside
    assert.deepEqual(await company.getOwners(), [user1]);
});
```

4. Check if an address is an owner
```javascript
it("4. should be able to check owner", async () => {
    const company = await Company.deployed();
    await company.addOwner(user1);

    // checkIfOwner() should true since user1 is in the ownerList   
    assert.equal(await company.checkIfOwner(user1), true);
});
```

5. Check if master is the only account to remove owner
```javascript
it("5. only master should be able to remove owners", async () => {
    const company = await Company.deployed();

    await truffleAssert.reverts(
        company.removeOwner(user1, {from: user2}),
    );
});
```

6. Check if Master is able to add owner
```javascript
it("6. master should be able to remove owners", async () => {
    const company = await Company.deployed();

    const tx = await company.removeOwner(user1);
    // check if OwnerRemoval event is emitted
    truffleAssert.eventEmitted(tx, "OwnerRemoval", (ev) => {
        return ev.owner == user1;
    });
    // ownerList should be empty
    assert.deepEqual(await company.getOwners(), []);
});
```

7. Check if Master is able to send his share to owners
```javascript
it("7. master should be able to send his share to owners", async() => {
    const company = await Company.deployed();
    // add user2 as owner
    await company.addOwner(user2);

    // the initial share is 5000000
    assert.equal(await company.getShare(user2), 5000000);

    // add the share of master to user2
    const tx1 = await company.addShare(user2, 1000);

    // check if Transfer event is getting emitted
    truffleAssert.eventEmitted(tx1, "Transfer", (ev) => {
        return ev.receiver == user2 && ev.amount == 1000
    });
    // get the share of user2
    const user2Share = await company.getShare(user2);

    // user2 share should be 5000000 + 1000 : 5001000
    assert.equal(user2Share.toString(), 5001000);
});
```

8. Check if it's not possible to user ``addShare()`` to transfer share to ordinary users

```javascript
it("8. should not be able to use addShare() to transfer share to non-admins(normal-users)", async() => {
    const company = await Company.deployed();

    await truffleAssert.reverts(
        company.addShare(user3, 1000),
    );
});
```

9. Check if it's possible to use ``giveShare()`` to transfer share to ordinary users

```javascript
it("9. should be able to use giveShare() to transfer share to anyone", async () => {
    const company = await Company.deployed();

    const tx = await company.giveShare(user3,  1500);
    truffleAssert.eventEmitted(tx, "Transfer", (ev) => {
        return ev.receiver == user3 && ev.amount == 1500;
    });

    assert.equal(await company.getShare(user3), 1500);
});
```

#### The whole test code
```javascript
const Company = artifacts.require("Company");
const truffleAssert = require('truffle-assertions');
contract("Company", (accounts) => {
    const user1 = accounts[0];
    const user2 = accounts[1];
    const user3 = accounts[2];
    console.log(accounts);
    it("1. should be able to set the right master", async () => {
        const company = await Company.deployed();
        assert.deepEqual(await company.getMaster(), user1);
    });
    it("2. only master should be able to add owner", async () => {
        const company = await Company.deployed();
        await truffleAssert.reverts(
            company.addOwner(user1, {from: user2}),
        );
    });
    it("3. master should be able to add owner", async() => {
        const company = await Company.deployed();
        const tx = await company.addOwner(user1);
        truffleAssert.eventEmitted(tx, "OwnerAddition", (ev) => {
            return ev.owner == user1;
        })

        assert.deepEqual(await company.getOwners(), [user1]);
    });
    it("4. should be able to check owner", async () => {
        const company = await Company.deployed();
        await company.addOwner(user1);
        
        assert.equal(await company.checkIfOwner(user1), true);
    });
    it("5. only master should be able to remove owners", async () => {
        const company = await Company.deployed();

        await truffleAssert.reverts(
            company.removeOwner(user1, {from: user2}),
            //"Only Master has the right to call"
        );
    });
    it("6. master should be able to remove owners", async () => {
        const company = await Company.deployed();

        const tx = await company.removeOwner(user1);
        truffleAssert.eventEmitted(tx, "OwnerRemoval", (ev) => {
            return ev.owner == user1;
        });
        assert.deepEqual(await company.getOwners(), []);
    });
    it("7. master should be able to send his share to owners", async() => {
        const company = await Company.deployed();

        await company.addOwner(user2);

        assert.equal(await company.getShare(user2), 5000000);

        const tx1 = await company.addShare(user2, 1000);
        truffleAssert.eventEmitted(tx1, "Transfer", (ev) => {
            return ev.receiver == user2 && ev.amount == 1000
        });

        const user2Share = await company.getShare(user2);

        assert.equal(user2Share.toString(), 5001000);
    });
    it("8. should not be able to use addShare() to transfer share to non-admins(normal-users)", async() => {
        const company = await Company.deployed();

        await truffleAssert.reverts(
            company.addShare(user3, 1000),
        );
    });
    it("9. should be able to use giveShare() to transfer share to anyone", async () => {
        const company = await Company.deployed();

        const tx = await company.giveShare(user3,  1500);
        truffleAssert.eventEmitted(tx, "Transfer", (ev) => {
            return ev.receiver == user3 && ev.amount == 1500;
        });

        assert.equal(await company.getShare(user3), 1500);
    });
})
```

#### Run test

```bash
$ truffle test --network mumbai
```

#### Test Result
![Test Result](https://i.ibb.co/Fqs3vjb/Screen-Shot-2021-10-22-at-9-24-47-AM.png)


### Conclusion
After reading this tutorial you'll able to :
- Write Smart Contract with solidity
- Use truffle library to unit test smart contract

### About the Author

[Please add my intro]

### References
- [Truffle](https://www.trufflesuite.com/)
- [Solidity](https://docs.soliditylang.org/en/v0.8.9/)
- [Polygon docs](https://docs.matic.network/docs/develop/getting-started)
