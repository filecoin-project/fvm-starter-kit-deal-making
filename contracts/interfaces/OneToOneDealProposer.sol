// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./BaseDealProposer.sol";

interface OneToOneDealProposer is BaseDealProposer {
    /**
    * OneToOneDealProposalCreate
    *
    * This event is emitted when a new deal is available to
    * storage providers from this client. Client needs to specify provider.
    *
    * @param id the miner ID of the provider (required)
    * @param id the unique identifer for this deal proposal (required)
    * @param size the data size of the deal itself (optional, can be left as 0 if not available)
    * @param verified true if the deal is verified, false otherwise (optional, can be left as false if unknown)
    * @param price the nanoFIL the client is offering for the deal per GiB per epoch of storage (optional, can be left as 0 if no price offered)
    */
    event OneToOneDealProposalCreate(
        bytes32 indexed provider, 
        bytes32 indexed id,
        uint64 size,
        bool indexed verified,
        uint256 price
    );
    
    /**
    * getDealProposal
    *
    * Given a unique identifier for an available deal proposal, return
    * the deal definition payload (with the provider field defined)
    *
    * @param id the unique identifer for this deal proposal
    * @return the deal definition for that deal proposal
    */
    function getDealProposal(bytes32 id) external view returns (DealDefinition memory);
}