# Postcommit Hook to Create a CRDT

#### Compile `postcommit_crdts_snippet.erl`

Produces `postcommit_crdts_snippet.beam`

```
erlc postcommit_crdts_snippet.erl
```

#### Copy the beam file to `$path_to/lib/basho-patches/`

```
cp postcommit_crdts_snippet.beam $path_to/lib/basho-patches/
```

#### Create bucket-types with the map DataType and postcommit hook specified

The `hooks` type will execute our postcommit hook on every insert.
The `maps` type will be the target for our programatically generated map objects.

```
riak-admin bucket-type create hooks '{"props":{"allow_mult":false, "postcommit":[{"mod": "postcommit_crdts_snippet","fun": "postcommit_create_crdt"}]}}'
riak-admin bucket-type activate hooks

riak-admin bucket-type create maps '{"props":{"datatype":"map"}}'
riak-admin bucket-type activate maps
```

#### Submit a json object with the following format:

```
curl -v -XPUT http://localhost:8098/types/hooks/buckets/myhookbucket/keys/test \
-H "Content-Type: application/json" \
-d '{
    "name": "Drew", 
    "email": "drew@kerrigan.io",
    "dest_type": "maps",
    "dest_bucket": "mymapbucket",
    "dest_key": "drew"
}'
```

#### Verify the object was created with a curl command like so:

```
curl -v http://localhost:8098/types/maps/buckets/mymapbucket/datatypes/drew
```
