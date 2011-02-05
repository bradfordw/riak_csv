-module(riak_csv_sup).

-behaviour(supervisor).

%% API
-export([start_link/0]).

%% Supervisor callbacks
-export([init/1]).

%% Helper macro for declaring children of supervisor
-define(CHILD(I, Type), {I, {I, start_link, []}, permanent, 5000, Type, [I]}).

%% ===================================================================
%% API functions
%% ===================================================================

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

%% ===================================================================
%% Supervisor callbacks
%% ===================================================================

init([]) ->
	Name = "csv",
	Proplist = [{prefix, Name},{riak,local}],
	Mod = riak_csv_file,
	[webmachine_router:add_route(Route) || Route <- [
	  {[Name], Mod, Proplist},
		{[Name, bucket], Mod, Proplist}
	]],
	{ok, { {one_for_one, 5, 10}, []} }.