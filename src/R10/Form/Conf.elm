module R10.Form.Conf exposing
    ( Conf
    , Entity(..)
    , EntityId
    , TextConf
    , filter
    , fromString
    , getId
    , init
    , toString
    )

import Json.Decode as D
import Json.Encode as E
import Json.Encode.Extra as E
import R10.Form.FieldConf


type alias EntityId =
    String


type alias TextConf =
    { title : String
    , helperText : Maybe String
    , validationSpecs : Maybe R10.Form.FieldConf.ValidationSpecs
    }


type Entity
    = EntityNormal EntityId (List Entity)
    | EntityWrappable EntityId (List Entity)
    | EntityWithBorder EntityId (List Entity)
    | EntityWithTabs EntityId (List Entity)
    | EntityMulti EntityId (List Entity)
    | EntityField R10.Form.FieldConf.FieldConf
    | EntityTitle EntityId TextConf
    | EntitySubTitle EntityId TextConf


type alias Conf =
    List Entity



-- ██   ██ ███████ ██      ██████  ███████ ██████  ███████
-- ██   ██ ██      ██      ██   ██ ██      ██   ██ ██
-- ███████ █████   ██      ██████  █████   ██████  ███████
-- ██   ██ ██      ██      ██      ██      ██   ██      ██
-- ██   ██ ███████ ███████ ██      ███████ ██   ██ ███████


init : List Entity
init =
    []


getId : Entity -> EntityId
getId entity =
    case entity of
        EntityNormal entityId _ ->
            entityId

        EntityWrappable entityId _ ->
            entityId

        EntityWithBorder entityId _ ->
            entityId

        EntityWithTabs entityId _ ->
            entityId

        EntityMulti entityId _ ->
            entityId

        EntityField fieldConf ->
            fieldConf.id

        EntityTitle _ titleConf ->
            titleConf.title

        EntitySubTitle _ titleConf ->
            titleConf.title


filter : EntityId -> List Entity -> List Entity
filter entityId listEntities =
    List.filter (\entity -> entityId == getId entity) listEntities



-- ███████ ███    ██ ████████ ██ ████████ ██    ██
-- ██      ████   ██    ██    ██    ██     ██  ██
-- █████   ██ ██  ██    ██    ██    ██      ████
-- ██      ██  ██ ██    ██    ██    ██       ██
-- ███████ ██   ████    ██    ██    ██       ██
--
-- ███████ ███    ██  ██████  ██████  ██████  ███████ ██████
-- ██      ████   ██ ██      ██    ██ ██   ██ ██      ██   ██
-- █████   ██ ██  ██ ██      ██    ██ ██   ██ █████   ██████
-- ██      ██  ██ ██ ██      ██    ██ ██   ██ ██      ██   ██
-- ███████ ██   ████  ██████  ██████  ██████  ███████ ██   ██


encoderGenericEntity : String -> List Entity -> String -> E.Value
encoderGenericEntity entityId listEntity string =
    E.object
        [ ( "EntityId", E.string entityId )
        , ( string, E.list encoderEntity listEntity )
        ]


decoderGenericEntity : (EntityId -> List Entity -> Entity) -> String -> D.Decoder Entity
decoderGenericEntity typeConstructor string =
    D.map2
        typeConstructor
        (D.field "EntityId" D.string)
        (D.field string <| D.list <| D.lazy <| \_ -> decoderEntity)


encoderGenericTitle : TextConf -> String -> E.Value
encoderGenericTitle titleConf string =
    E.object
        [ ( string
          , E.object
                [ ( "Title", E.string titleConf.title )
                , ( "HelperText", E.maybe E.string titleConf.helperText )
                , ( "ValidationSpecs", E.maybe R10.Form.FieldConf.encodeValidationSpecs titleConf.validationSpecs )
                ]
          )
        ]


decoderGenericTitle : (EntityId -> TextConf -> Entity) -> String -> D.Decoder Entity
decoderGenericTitle typeConstructor string =
    D.map2
        typeConstructor
        (D.field "EntityId" D.string)
        (D.field string <|
            D.map3
                TextConf
                (D.field "Title" D.string)
                (D.field "HelperText" (D.maybe D.string))
                (D.field "ValidationSpecs" (D.maybe R10.Form.FieldConf.decoderValidationSpecs))
        )


encoderEntity : Entity -> E.Value
encoderEntity entity2 =
    case entity2 of
        EntityNormal entityId listEntity ->
            encoderGenericEntity entityId listEntity "EntityNormal"

        EntityWrappable entityId listEntity ->
            encoderGenericEntity entityId listEntity "EntityWrappable"

        EntityWithBorder entityId listEntity ->
            encoderGenericEntity entityId listEntity "EntityWithBorder"

        EntityWithTabs entityId listEntity ->
            encoderGenericEntity entityId listEntity "EntityWithTabs"

        EntityMulti entityId listEntity ->
            encoderGenericEntity entityId listEntity "EntityMulti"

        EntityTitle _ titleConf ->
            encoderGenericTitle titleConf "EntityTitle"

        EntitySubTitle _ titleConf ->
            encoderGenericTitle titleConf "EntitySubTitle"

        EntityField fieldConf ->
            R10.Form.FieldConf.encoderFieldConf fieldConf


decoderEntity : D.Decoder Entity
decoderEntity =
    D.oneOf
        [ decoderGenericEntity EntityNormal "EntityNormal"
        , decoderGenericEntity EntityWrappable "EntityWrappable"
        , decoderGenericEntity EntityWithBorder "EntityWithBorder"
        , decoderGenericEntity EntityWithTabs "EntityWithTabs"
        , decoderGenericEntity EntityMulti "EntityMulti"
        , decoderGenericTitle EntityTitle "EntityTitle"
        , decoderGenericTitle EntitySubTitle "EntitySubTitle"
        , D.map EntityField R10.Form.FieldConf.decoderFieldConf
        ]


toString : Conf -> String
toString v =
    E.encode 4 <| E.list encoderEntity v


fromString : String -> Result D.Error Conf
fromString string =
    D.decodeString (D.list decoderEntity) string
