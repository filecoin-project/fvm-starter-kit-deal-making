// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

struct DealDefinitionNoProvider {
    bytes piece_cid;
    uint64 piece_size;
    bool verified_deal;
    string label;
    int64 start_epoch;
    int64 end_epoch;
    uint256 storage_price_per_epoch;
    uint256 provider_collateral;
    uint256 client_collateral;
    uint64 extra_params_version;
    ExtraParamsV1 extra_params;
}

struct DealDefinition {
    bytes piece_cid;
    bytes provider;
    uint64 piece_size;
    bool verified_deal;
    string label;
    int64 start_epoch;
    int64 end_epoch;
    uint256 storage_price_per_epoch;
    uint256 provider_collateral;
    uint256 client_collateral;
    uint64 extra_params_version;
    ExtraParamsV1 extra_params;
}


struct ExtraParamsV1 {
    string location_ref;
    uint64 car_size;
    bool skip_ipni_announce;
    bool remove_unsealed_copy;
}

interface BaseDealProposer {
    event ClientContractDeployed();

    /**
    * handle_filecoin_method
    *
    * This is the entry point for all built-in actor calls. This
    * must be properly dispatched to provide a client signature verification
    * of a proven deal from a storage provider, notify, or receive data cap.
    *
    * @param method the method ID the built-in actor is attempting to call
    * @param _unused ignored paramter
    * @param params the calldata parameters associated with the method.
    * @return exit code Standard exit codes according to the built-in actors' calling convention.
    * @return codec ??
    * @return memory the data itself
    */
    function handle_filecoin_method(
            uint64 method,
            uint64 _unused,
            bytes memory params)
    external returns (uint32 exit, uint64 codec, bytes memory);
}