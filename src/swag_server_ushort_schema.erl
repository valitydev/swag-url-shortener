%% -*- mode: erlang -*-
-module(swag_server_ushort_schema).

-export([get/0]).
-export([get_raw/0]).
-export([enumerate_discriminator_children/1]).

-define(DEFINITIONS, <<"definitions">>).

-spec get() -> swag_server_ushort:object().
get() ->
    ct_expand:term(enumerate_discriminator_children(maps:with([?DEFINITIONS], get_raw()))).

-spec enumerate_discriminator_children(Schema :: map()) ->
    Schema :: map() | no_return().
enumerate_discriminator_children(Schema = #{?DEFINITIONS := Defs}) ->
    try
        Parents = enumerate_parents(Defs),
        DefsFixed = maps:fold(fun correct_definition/3, Defs, Parents),
        Schema#{?DEFINITIONS := DefsFixed}
    catch
        _:Error ->
            handle_error(Error)
    end;
enumerate_discriminator_children(_) ->
    handle_error(no_definitions).

-spec handle_error(_) ->
    no_return().
handle_error(Error) ->
    erlang:error({schema_invalid, Error}).

enumerate_parents(Definitions) ->
    maps:fold(
        fun
            (Name, #{<<"allOf">> := AllOf}, AccIn) ->
                lists:foldl(
                    fun
                        (#{<<"$ref">> := <<"#/definitions/", Parent/binary>>}, Acc) ->
                            Schema = maps:get(Parent, Definitions),
                            Discriminator = maps:get(<<"discriminator">>, Schema, undefined),
                            add_parent_child(Discriminator, Parent, Name, Acc);
                        (_Schema, Acc) ->
                            Acc
                    end,
                    AccIn,
                    AllOf
                );
            (Name, #{<<"discriminator">> := _}, Acc) ->
                add_parent(Name, Acc);
            (_Name, _Schema, AccIn) ->
                AccIn
        end,
        #{},
        Definitions
    ).

add_parent_child(undefined, _Parent, _Child, Acc) ->
    Acc;
add_parent_child(_Discriminator, Parent, Child, Acc) ->
    maps:put(Parent, [Child | maps:get(Parent, Acc, [])], Acc).

add_parent(Parent, Acc) when not is_map_key(Parent, Acc) ->
    maps:put(Parent, [], Acc);
add_parent(_Parent, Acc) ->
    Acc.

correct_definition(Parent, Children, Definitions) ->
    ParentSchema1 = maps:get(Parent, Definitions),
    Discriminator = maps:get(<<"discriminator">>, ParentSchema1),
    ParentSchema2 = deep_put([<<"properties">>, Discriminator, <<"enum">>], Children, ParentSchema1),
    maps:put(Parent, ParentSchema2, Definitions).

deep_put([K], V, M) ->
    M#{K => V};
deep_put([K | Ks], V, M) ->
    maps:put(K, deep_put(Ks, V, maps:get(K, M)), M).

-spec get_raw() -> map().
get_raw() ->
    #{
  <<"swagger">> => <<"2.0">>,
  <<"info">> => #{
    <<"description">> => <<"URL shortener API\n">>,
    <<"version">> => <<"1.0">>,
    <<"title">> => <<"RBKmoney URL shortener API">>,
    <<"termsOfService">> => <<"http://rbkmoney.com/">>,
    <<"contact">> => #{
      <<"name">> => <<"RBKmoney support team">>,
      <<"url">> => <<"https://api.rbk.money">>,
      <<"email">> => <<"tech-support@rbkmoney.com">>
    }
  },
  <<"host">> => <<"rbk.mn">>,
  <<"basePath">> => <<"/v1">>,
  <<"tags">> => [ #{
    <<"name">> => <<"Shortener">>,
    <<"description">> => <<"Получение и работа с короткими ссылками">>,
    <<"x-displayName">> => <<"Короткие ссылки">>
  } ],
  <<"schemes">> => [ <<"https">> ],
  <<"consumes">> => [ <<"application/json; charset=utf-8">> ],
  <<"produces">> => [ <<"application/json; charset=utf-8">> ],
  <<"security">> => [ #{
    <<"bearer">> => [ ]
  } ],
  <<"paths">> => #{
    <<"/shortened-urls">> => #{
      <<"post">> => #{
        <<"tags">> => [ <<"Shortener">> ],
        <<"description">> => <<"Создать новую короткую ссылку">>,
        <<"operationId">> => <<"shortenUrl">>,
        <<"parameters">> => [ #{
          <<"name">> => <<"X-Request-ID">>,
          <<"in">> => <<"header">>,
          <<"description">> => <<"Уникальный идентификатор запроса к системе">>,
          <<"required">> => true,
          <<"type">> => <<"string">>,
          <<"maxLength">> => 32,
          <<"minLength">> => 1
        }, #{
          <<"in">> => <<"body">>,
          <<"name">> => <<"shortenedUrlParams">>,
          <<"description">> => <<"Параметры для создания короткой ссылки">>,
          <<"required">> => true,
          <<"schema">> => #{
            <<"$ref">> => <<"#/definitions/ShortenedUrlParams">>
          }
        } ],
        <<"responses">> => #{
          <<"201">> => #{
            <<"description">> => <<"Короткая ссылка создана">>,
            <<"schema">> => #{
              <<"$ref">> => <<"#/definitions/ShortenedUrl">>
            }
          },
          <<"400">> => #{
            <<"description">> => <<"Неверные данные запроса">>,
            <<"schema">> => #{
              <<"$ref">> => <<"#/definitions/inline_response_400">>
            }
          },
          <<"401">> => #{
            <<"description">> => <<"Операция требует авторизации">>
          },
          <<"403">> => #{
            <<"description">> => <<"Операция недоступна">>
          }
        }
      }
    },
    <<"/shortened-urls/{shortenedUrlID}">> => #{
      <<"get">> => #{
        <<"tags">> => [ <<"Shortener">> ],
        <<"description">> => <<"Получить данные созданной короткой ссылки">>,
        <<"operationId">> => <<"getShortenedUrl">>,
        <<"parameters">> => [ #{
          <<"name">> => <<"X-Request-ID">>,
          <<"in">> => <<"header">>,
          <<"description">> => <<"Уникальный идентификатор запроса к системе">>,
          <<"required">> => true,
          <<"type">> => <<"string">>,
          <<"maxLength">> => 32,
          <<"minLength">> => 1
        }, #{
          <<"name">> => <<"shortenedUrlID">>,
          <<"in">> => <<"path">>,
          <<"description">> => <<"Идентификатор короткой ссылки">>,
          <<"required">> => true,
          <<"type">> => <<"string">>
        } ],
        <<"responses">> => #{
          <<"200">> => #{
            <<"description">> => <<"Данные короткой ссылки">>,
            <<"schema">> => #{
              <<"$ref">> => <<"#/definitions/ShortenedUrl">>
            }
          },
          <<"400">> => #{
            <<"description">> => <<"Неверные данные запроса">>,
            <<"schema">> => #{
              <<"$ref">> => <<"#/definitions/inline_response_400">>
            }
          },
          <<"401">> => #{
            <<"description">> => <<"Операция требует авторизации">>
          },
          <<"403">> => #{
            <<"description">> => <<"Операция недоступна">>
          },
          <<"404">> => #{
            <<"description">> => <<"Объект не найден">>
          }
        }
      },
      <<"delete">> => #{
        <<"tags">> => [ <<"Shortener">> ],
        <<"description">> => <<"Удалить короткую ссылку">>,
        <<"operationId">> => <<"deleteShortenedUrl">>,
        <<"parameters">> => [ #{
          <<"name">> => <<"X-Request-ID">>,
          <<"in">> => <<"header">>,
          <<"description">> => <<"Уникальный идентификатор запроса к системе">>,
          <<"required">> => true,
          <<"type">> => <<"string">>,
          <<"maxLength">> => 32,
          <<"minLength">> => 1
        }, #{
          <<"name">> => <<"shortenedUrlID">>,
          <<"in">> => <<"path">>,
          <<"description">> => <<"Идентификатор короткой ссылки">>,
          <<"required">> => true,
          <<"type">> => <<"string">>
        } ],
        <<"responses">> => #{
          <<"204">> => #{
            <<"description">> => <<"Короткая ссылка удалена">>
          },
          <<"400">> => #{
            <<"description">> => <<"Неверные данные запроса">>,
            <<"schema">> => #{
              <<"$ref">> => <<"#/definitions/inline_response_400">>
            }
          },
          <<"401">> => #{
            <<"description">> => <<"Операция требует авторизации">>
          },
          <<"403">> => #{
            <<"description">> => <<"Операция недоступна">>
          },
          <<"404">> => #{
            <<"description">> => <<"Объект не найден">>
          }
        }
      }
    }
  },
  <<"securityDefinitions">> => #{
    <<"bearer">> => #{
      <<"description">> => <<"Для аутентификации вызовов мы используем [JWT](https://jwt.io). Cоответствующий ключ передается в заголовке.\n```shell\n Authorization: Bearer {TOKENIZATION|PRIVATE_JWT}\n```\nПосмотреть ваш API-ключ вы можете в [личном кабинете](https://dashboard.rbk.money/api/key). Ключи не разделяются на тестовые и боевые, ваш API ключ открывает доступ ко всем функциям платформы. Для тестовых транзакций используйте ID тестовых магазинов. Помните, что вы никому не должны передавать ваш API ключ!\n">>,
      <<"type">> => <<"apiKey">>,
      <<"name">> => <<"Authorization">>,
      <<"in">> => <<"header">>
    }
  },
  <<"definitions">> => #{
    <<"ShortenedUrl">> => #{
      <<"type">> => <<"object">>,
      <<"required">> => [ <<"expiresAt">>, <<"id">>, <<"shortenedUrl">>, <<"sourceUrl">> ],
      <<"properties">> => #{
        <<"id">> => #{
          <<"type">> => <<"string">>
        },
        <<"shortenedUrl">> => #{
          <<"type">> => <<"string">>,
          <<"format">> => <<"uri">>
        },
        <<"sourceUrl">> => #{
          <<"type">> => <<"string">>,
          <<"format">> => <<"uri">>
        },
        <<"expiresAt">> => #{
          <<"type">> => <<"string">>,
          <<"format">> => <<"date-time">>
        }
      },
      <<"example">> => #{
        <<"sourceUrl">> => <<"http://example.com/aeiou">>,
        <<"shortenedUrl">> => <<"http://example.com/aeiou">>,
        <<"id">> => <<"id">>,
        <<"expiresAt">> => <<"2000-01-23T04:56:07.000+00:00">>
      }
    },
    <<"ShortenedUrlParams">> => #{
      <<"type">> => <<"object">>,
      <<"required">> => [ <<"expiresAt">>, <<"sourceUrl">> ],
      <<"properties">> => #{
        <<"sourceUrl">> => #{
          <<"type">> => <<"string">>,
          <<"format">> => <<"uri">>
        },
        <<"expiresAt">> => #{
          <<"type">> => <<"string">>,
          <<"format">> => <<"date-time">>
        }
      },
      <<"example">> => #{
        <<"sourceUrl">> => <<"http://example.com/aeiou">>,
        <<"expiresAt">> => <<"2000-01-23T04:56:07.000+00:00">>
      }
    },
    <<"inline_response_400">> => #{
      <<"type">> => <<"object">>,
      <<"required">> => [ <<"code">>, <<"message">> ],
      <<"properties">> => #{
        <<"code">> => #{
          <<"type">> => <<"string">>
        },
        <<"message">> => #{
          <<"type">> => <<"string">>
        }
      }
    }
  },
  <<"parameters">> => #{
    <<"requestID">> => #{
      <<"name">> => <<"X-Request-ID">>,
      <<"in">> => <<"header">>,
      <<"description">> => <<"Уникальный идентификатор запроса к системе">>,
      <<"required">> => true,
      <<"type">> => <<"string">>,
      <<"maxLength">> => 32,
      <<"minLength">> => 1
    },
    <<"shortenedUrlID">> => #{
      <<"name">> => <<"shortenedUrlID">>,
      <<"in">> => <<"path">>,
      <<"description">> => <<"Идентификатор короткой ссылки">>,
      <<"required">> => true,
      <<"type">> => <<"string">>
    }
  },
  <<"responses">> => #{
    <<"NotFound">> => #{
      <<"description">> => <<"Объект не найден">>
    },
    <<"Unauthorized">> => #{
      <<"description">> => <<"Операция требует авторизации">>
    },
    <<"Forbidden">> => #{
      <<"description">> => <<"Операция недоступна">>
    },
    <<"BadRequest">> => #{
      <<"description">> => <<"Неверные данные запроса">>,
      <<"schema">> => #{
        <<"$ref">> => <<"#/definitions/inline_response_400">>
      }
    }
  }
}.

-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").

-define(SCHEMA,
  <<"{\"definitions\": {
       \"Pet\": {
         \"type\":          \"object\",
         \"discriminator\": \"petType\",
         \"properties\": {
            \"name\":    {\"type\": \"string\"},
            \"petType\": {\"type\": \"string\"}
         },
         \"required\": [\"name\", \"petType\"]
       },
       \"Cat\": {
         \"description\": \"A representation of a cat\",
         \"allOf\": [
           {\"$ref\": \"#/definitions/Pet\"},
           {
             \"type\":       \"object\",
             \"properties\": {
               \"huntingSkill\": {
                 \"type\":        \"string\",
                 \"description\": \"The measured skill for hunting\",
                 \"default\":     \"lazy\",
                 \"enum\":        [\"clueless\", \"lazy\", \"adventurous\", \"aggressive\"]
               }
             },
             \"required\": [\"huntingSkill\"]
           }
         ]
       },
       \"Dog\": {
         \"description\": \"A representation of a dog\",
         \"allOf\": [
           {\"$ref\": \"#/definitions/Pet\"},
           {
             \"type\":       \"object\",
             \"properties\": {
               \"packSize\": {
                 \"type\":        \"integer\",
                 \"format\":      \"int32\",
                 \"description\": \"the size of the pack the dog is from\",
                 \"default\":     0,
                 \"minimum\":     0
               }
             }
           }
         ],
         \"required\": [\"packSize\"]
       },
       \"Person\": {
         \"type\":          \"object\",
         \"discriminator\": \"personType\",
         \"properties\": {
           \"name\": {\"type\": \"string\"},
           \"sex\": {
             \"type\": \"string\",
             \"enum\": [\"male\", \"female\"]
           },
           \"personType\": {\"type\": \"string\"}
         },
         \"required\": [\"name\", \"sex\", \"personType\"]
       },
       \"WildMix\": {
         \"allOf\": [
           {\"$ref\": \"#/definitions/Pet\"},
           {\"$ref\": \"#/definitions/Person\"}
         ],
       },
       \"Dummy\": {
         \"type\":          \"object\",
         \"discriminator\": \"dummyType\",
         \"properties\": {
           \"name\":      {\"type\": \"string\"},
           \"dummyType\": {\"type\": \"string\"}
         },
         \"required\": [\"name\", \"dummyType\"]
       }
     }}">>).

get_enum(Parent, Discr, Schema) ->
    lists:sort(deep_get([?DEFINITIONS, Parent, <<"properties">>, Discr, <<"enum">>], Schema)).

deep_get([K], M) ->
    maps:get(K, M);
deep_get([K | Ks], M) ->
    deep_get(Ks, maps:get(K, M)).

-spec test() -> _.
-spec enumerate_discriminator_children_test() -> _.
enumerate_discriminator_children_test() ->
    Schema      = jsx:decode(?SCHEMA, [return_maps]),
    FixedSchema = enumerate_discriminator_children(Schema),
    ?assertEqual(lists:sort([<<"Dog">>, <<"Cat">>, <<"WildMix">>]), get_enum(<<"Pet">>, <<"petType">>, FixedSchema)),
    ?assertEqual([<<"WildMix">>], get_enum(<<"Person">>,  <<"personType">>, FixedSchema)),
    ?assertEqual([],              get_enum(<<"Dummy">>,   <<"dummyType">>,  FixedSchema)).

-spec get_test() -> _.
get_test() ->
    ?assertEqual(
       enumerate_discriminator_children(maps:with([?DEFINITIONS], get_raw())),
       ?MODULE:get()
    ).
-endif.
