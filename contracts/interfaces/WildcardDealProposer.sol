// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./BaseDealProposer.sol";

interface WildcardDealProposer is BaseDealProposer {
    /**
    * WildcardDealProposalCreate
    *
    * This event is emitted when a new deal is available to
    * storage providers from this client. Client does not need to specify provider.
    *
    * @param id the unique identifer for this deal proposal (required)
    * @param size the data size of the deal itself (optional, can be left as 0 if not available)
    * @param verified true if the deal is verified, false otherwise (optional, can be left as false if unknown)
    * @param price the nanoFIL the client is offering for the deal per GiB per epoch of storage (optional, can be left as 0 if no price offered)
    */
    event WildcardDealProposalCreate(
        bytes32 indexed id,
        uint64 size,
        bool indexed verified,
        uint256 price
    );

    /**
    * subscribe
    *
    * Subscribe the caller to all subsequent deals proposed by the contract.
    * This means the caller is electing to add themselves
        * as a candidate to all future deals emmitted by the contract.
        * Meant to be called by SPs, not simple ethereum accounts.
        *
    */
    function subscribe() external;

    /**
    * unsubscribe
    *
    * Unsubscribe the caller to all subsequent deals proposed by the contract.
        * Meant to be called by SPs, not simple ethereum accounts.
        *
    */
    function unsubscribe() external;

    /**
    * getDealProposal
    *
    * Given a unique identifier for an available deal proposal, return
    * the deal definition payload (without the provider field)
    *
    * @param id the unique identifer for this deal proposal
    * @return the deal definition for that deal proposal
    */
    function getDealProposal(bytes32 id) external view returns (DealDefinitionNoProvider memory);

    /**
    * getSPOrdering
    *
    * Given a unique identifier for an available deal proposal, return
    * the ordering of SPs that are subscribed to receive this deal proposal
    * from the contract.
    *
    * @return an array of addresses, where the first entry has the highest rank
    */
    function getSPOrdering(bytes32 id) external view returns (address[] memory);
}