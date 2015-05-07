-module(postcommit_crdts_snippet).
-export([postcommit_create_crdt/1]).
-record(crdt_op, {mod, op, ctx}).

postcommit_create_crdt(Object) ->
    %% Decode the JSON body of the object
    {struct, Properties} = mochijson2:decode(riak_object:get_value(Object)),

    %% Extract the relevant fields
    {<<"name">>,Name} = lists:keyfind(<<"name">>,1,Properties),
    {<<"email">>,Email} = lists:keyfind(<<"email">>,1,Properties),
    {<<"dest_type">>,T} = lists:keyfind(<<"dest_type">>,1,Properties),
    {<<"dest_bucket">>,B} = lists:keyfind(<<"dest_bucket">>,1,Properties),
    {<<"dest_key">>,Key} = lists:keyfind(<<"dest_key">>,1,Properties),

    %% Build the operation
    BProps = riak_core_bucket:get_bucket({T, B}),
    DataType = proplists:get_value(datatype, BProps),
    EncodedJSON = "{\"update\": {\"first_name_register\": \"" ++
        binary_to_list(Name) ++ "\",\"email_register\": \"" ++
        binary_to_list(Email) ++ "\"}}",
    DecodedJSON = mochijson2:decode(EncodedJSON),
    ModMap = riak_kv_crdt:mod_map(DataType),
    {_, Op, Context} = riak_kv_crdt_json:update_request_from_json(DataType, DecodedJSON, ModMap),
    Mod = riak_kv_crdt:to_mod(DataType),
    CrdtOp = #crdt_op{mod=Mod, op=Op, ctx=Context},

    
    %% Get a riak client
    {ok, C} = riak:local_client(),

    %% Create the object
    O = riak_kv_crdt:new({T, B}, Key, Mod),
    Options = [{crdt_op, CrdtOp},{retry_put_coordinator_failure,false}],

    %% Store the object
    C:put(O, Options).