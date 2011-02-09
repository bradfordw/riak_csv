-module(riak_csv_file).

-export([
         init/1,
         content_types_provided/2,
         service_available/2,
         export_bucket/2,
				 to_csv/4,
				 to_csv/5,
				 join/2,
				 bucket_to_csv/3,
				 doc_to_csv/2,
				 get_doc_properties/3
        ]).
 
-include_lib("webmachine/include/webmachine.hrl").
 
-record(ctx, {}).
%% Not actually using this to provide state...yet.
 
init(_) ->
	{ok, #ctx{}}.
 
content_types_provided(ReqData, Context) ->
	{[{"text/plain", export_bucket}], ReqData, Context}.
 
service_available(ReqData, Context) -> % 100% uptime, ya heard?
	{true, ReqData, Context}.
 
export_bucket(ReqData, Context) -> %% Todo get host,port from config!
	{ok, Pid} = riakc_pb_socket:start_link("127.0.0.1", 8081),
	Body = case wrq:path_info(bucket, ReqData) of
		undefined -> <<"">>;
		Bucket when is_list(Bucket) ->
			BinBucket = list_to_binary(Bucket),
			{ok, Keys} = riakc_pb_socket:list_keys(Pid, BinBucket),
			bucket_to_csv(Pid, BinBucket, Keys)
	end,
	{Body, ReqData, Context}.
	
%% private functions that I export...console debuggery ftw
 
bucket_to_csv(Pid, Bucket, Keys) ->
	Props = get_doc_properties(Pid, Bucket, hd(Keys)),
	to_csv(Pid, Bucket, Props, Keys).
 
to_csv(Pid, Bucket, Props, Keys) ->
	to_csv(Pid, Bucket, Props, <<"">>, Keys).
 
to_csv(Pid, Bucket, Props, Csv, [Key|Keys]) ->
	{ok, Object} = riakc_pb_socket:get(Pid, Bucket, Key),
	Entry = doc_to_csv(Object, Props),
	NewCsv = case Keys of
		[] -> <<Csv/binary, 34, Entry/binary, 34>>; %% end of dump
		_ -> <<Csv/binary, 34, Entry/binary, 34, 10>>
	end,
	to_csv(Pid, Bucket, Props, NewCsv, Keys);
 
to_csv(_Pid, _Bucket, _Props, Csv, []) -> 
	Csv.
 
get_doc_properties(Pid, Bucket, Key) ->
	{ok, Object} = riakc_pb_socket:get(Pid, Bucket, Key),
	case riakc_obj:get_value(Object) of
		V when is_binary(V) -> %% parse json
			case mochijson2:decode(V) of
     		{struct, Doc} ->
					proplists:get_keys(Doc);
				_ ->
					[]
			end;
		_ ->
			[]
	end.
 
doc_to_csv(Object, Props) ->
	case riakc_obj:get_value(Object) of
		Contents when is_binary(Contents) -> %% parse json
			case mochijson2:decode(Contents) of
     		{struct, Doc} ->
					Vals = [V || {_,V} <- [proplists:lookup(P,Doc) || P <- Props]], %%TODO: need to catch none atoms
					%% mmm, can probably do this with a catch on the case; will investigate.
					list_to_binary(join(Vals,[<<34,44,34>>]));
				_ ->
					<<"">>
			end;
		_ ->
			<<"">>
	end.
 
%% this join code is from: http://www.erlang.org/pipermail/erlang-questions/2007-September/029212.html
join([], _) -> [];
join([List|Lists], Separator) ->
	lists:flatten([List | [[Separator,Next] || Next <- Lists]]).