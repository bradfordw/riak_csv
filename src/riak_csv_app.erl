-module(riak_csv_app).

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1]).

%% ===================================================================
%% Application callbacks
%% ===================================================================

start(_StartType, _StartArgs) ->
		riak_core_util:start_app_deps(riak_csv),
    riak_csv_sup:start_link(),
		{ok,self()}.

stop(_State) ->
    ok.
