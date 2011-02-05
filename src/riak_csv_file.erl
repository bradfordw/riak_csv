-module(riak_csv_file).

-export([
         init/1,
         content_types_provided/2,
         service_available/2,
         to_csv/2
        ]).

-include_lib("webmachine/include/webmachine.hrl").

-record(ctx, {}).

init(_) ->
	{ok, #ctx{}}.

content_types_provided(ReqData, Context) ->
	{[{"text/plain", to_csv}],ReqData, Context}.

service_available(ReqData, Context) ->
	{true, ReqData, Context}.

to_csv(ReqData, Context) ->
    Body = <<"I am a CSV">>,
    {Body, ReqData, Context}.