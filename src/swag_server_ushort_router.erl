-module(swag_server_ushort_router).

-export([get_paths/1]).
-export([get_paths/2]).
-export([get_operation/1]).
-export([get_operations/0]).

-type operations() :: #{
    Method :: binary() => OperationID :: swag_server_ushort:operation_id()
}.

-type logic_handler(T) :: swag_server_ushort:logic_handler(T).

-type swagger_handler_opts() :: #{
    validation_opts => swag_server_ushort_validation:validation_opts()
}.

-type init_opts() :: {
    Operations      :: operations(),
    LogicHandler    :: logic_handler(_),
    SwaggerHandlerOpts :: swagger_handler_opts()
}.

-type operation_spec() :: #{
    path    := '_' | iodata(),
    method  := binary(),
    handler := module()
}.

-export_type([swagger_handler_opts/0]).
-export_type([init_opts/0]).
-export_type([operation_spec/0]).

-spec get_paths(LogicHandler :: logic_handler(_)) ->  [{'_',[{
    Path :: string(),
    Handler :: atom(),
    InitOpts :: init_opts()
}]}].

get_paths(LogicHandler) ->
    get_paths(LogicHandler, #{}).

-spec get_paths(LogicHandler :: logic_handler(_), SwaggerHandlerOpts :: swagger_handler_opts()) ->  [{'_',[{
    Path :: string(),
    Handler :: atom(),
    InitOpts :: init_opts()
}]}].

get_paths(LogicHandler, SwaggerHandlerOpts) ->
    PreparedPaths = maps:fold(
        fun(Path, #{operations := Operations, handler := Handler}, Acc) ->
            [{Path, Handler, Operations} | Acc]
        end,
        [],
        group_paths()
    ),
    [
        {'_',
            [{P, H, {O, LogicHandler, SwaggerHandlerOpts}} || {P, H, O} <- PreparedPaths]
        }
    ].

group_paths() ->
    maps:fold(
        fun(OperationID, #{path := Path, method := Method, handler := Handler}, Acc) ->
            case maps:find(Path, Acc) of
                {ok, PathInfo0 = #{operations := Operations0}} ->
                    Operations = Operations0#{Method => OperationID},
                    PathInfo = PathInfo0#{operations => Operations},
                    Acc#{Path => PathInfo};
                error ->
                    Operations = #{Method => OperationID},
                    PathInfo = #{handler => Handler, operations => Operations},
                    Acc#{Path => PathInfo}
            end
        end,
        #{},
        get_operations()
    ).

-spec get_operation(swag_server_ushort:operation_id()) ->
   operation_spec().

get_operation(OperationId) ->
    maps:get(OperationId, get_operations()).

-spec get_operations() -> #{
    swag_server_ushort:operation_id() := operation_spec()
}.

get_operations() ->
    #{ 
        'DeleteShortenedUrl' => #{
            path => "/v1/shortened-urls/:shortenedUrlID",
            method => <<"DELETE">>,
            handler => 'swag_server_ushort_shortener_handler'
        },
        'GetShortenedUrl' => #{
            path => "/v1/shortened-urls/:shortenedUrlID",
            method => <<"GET">>,
            handler => 'swag_server_ushort_shortener_handler'
        },
        'ShortenUrl' => #{
            path => "/v1/shortened-urls",
            method => <<"POST">>,
            handler => 'swag_server_ushort_shortener_handler'
        }
    }.
