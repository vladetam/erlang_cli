-module(cli_records).
-export([start/0]).

start() ->
    Shipments = seed(),
    loop(Shipments).

-record(shipment, {
    id,
    weight,
    destination,
    status
}).

seed() ->
    [
        #shipment{id=1, weight=120, destination="london", status=pending},
        #shipment{id=2, weight=50, destination="paris", status=in_transit},
        #shipment{id=3, weight=200, destination="berlin", status=delivered},
        #shipment{id=4, weight=75, destination="london", status=pending},
        #shipment{id=5, weight=90, destination="madrid", status=delivered},
        #shipment{id=6, weight=110, destination="rome", status=pending},
        #shipment{id=7, weight=60, destination="paris", status=pending},
        #shipment{id=8, weight=140, destination="berlin", status=in_transit},
        #shipment{id=9, weight=30, destination="rome", status=delivered},
        #shipment{id=10, weight=80, destination="london", status=pending}
    ].

loop(Shipments) ->
    menu(),
    Input = string:trim(io:get_line("Selection > ")),
    handle_input(Input, Shipments).

handle_input("1", Shipments) ->
    view_all(Shipments),
    loop(Shipments);

handle_input("2", Shipments) ->
    filter(Shipments),
    loop(Shipments);

handle_input("3", Shipments) ->
    stats(Shipments),
    loop(Shipments);

handle_input("4", Shipments) ->
     New=dispatch(Shipments),
        io:format("From Pending to In Transit~n"),
            loop(New);

handle_input("5", Shipments) ->
    NewShipments=add_shipment(Shipments),
    io:format("Adding New Shipment...~n"),
     loop(NewShipments);
    
handle_input("6",_) ->
    io:format("Exiting Terminal...~n"),
    ok;

handle_input(_, Shipments) ->
     io:format("Invalid selection.~n"),
            loop(Shipments).

menu() ->
    io:format("~n1. View All | 2. Filter | 3. Statistics | 4. Dispatch | 5. Add Shipment | 6. Exit~n").

print_shipment(S) ->
    io:format(
        "ID: ~p | Weight: ~p | Dest: ~s | Status: ~p~n",
        [
            S#shipment.id,
            S#shipment.weight,
            S#shipment.destination,
            S#shipment.status
        ]
    ).

view_all([]) ->
    ok;

view_all([H | T]) ->
    print_shipment(H),
    view_all(T).

is_letter(Character) ->
    Character >= $a andalso Character =< $z.

filter(Shipments) ->
    Input = io:get_line("Destination > "),
    TrimInput = string:trim(Input),
    LowerInput = string:lowercase(TrimInput),

    case LowerInput of
        "" ->
            io:format("Invalid input. Please enter a destination.~n");

        _ ->
            case lists:all(fun(Character) -> is_letter(Character) end, LowerInput) of
                true ->
                    run_filter(Shipments, LowerInput);

                false ->
                    io:format("Invalid input. Destination must contain only letters.~n")
            end
    end.

run_filter(Shipments, Dest) ->
    Filtered =
        lists:filter(
            fun(S) ->
                S#shipment.destination =:= Dest
            end,
            Shipments
        ),

    show_filtered(Filtered).

show_filtered([]) ->
    io:format("No shipments found.~n");

show_filtered(Shipments) ->
    view_all(Shipments).

stats(Shipments) ->
    try
        {Weight, Delivered} =
            lists:foldl(
                fun(S, {AccW, AccD}) ->
                    W = S#shipment.weight,
                    Status = S#shipment.status,

                    case W =< 0 of
                        true -> throw(invalid_weight);
                        false -> ok
                    end,

                    PendingAdd =
                        case Status of
                            pending -> W;
                            _ -> 0
                        end,

                    DeliveredAdd =
                        case Status of
                            delivered -> 1;
                            _ -> 0
                        end,

                    {AccW + PendingAdd, AccD + DeliveredAdd}
                end,
                {0,0},
                Shipments
            ),

        io:format(
            "Stats: Total Pending Weight: ~pkg | Total Delivered: ~p~n",
            [Weight, Delivered]
        )

    catch
        invalid_weight ->
            io:format("Error: Invalid shipment weight detected.~n")
    end.

dispatch(Shipments) ->
    lists:map(
        fun(S = #shipment{status = pending}) ->
            S#shipment{status = in_transit};
        (S) ->
            S
        end,
        Shipments
    ).

add_shipment(Shipments) ->
    Weight = get_valid_weight(),
    Destination = get_valid_destination(),
    ID = get_next_id(Shipments),

    NewShipment = #shipment{
        id = ID,
        weight = Weight,
        destination = Destination,
        status = pending
    },

    NewList = add_to_end(Shipments, NewShipment),

    io:format("Shipment added with ID: ~p~n", [ID]),

    NewList.

get_valid_weight() ->
    Input = string:trim(io:get_line("Weight > ")),

    case string:to_integer(Input) of
        {Weight, ""} when Weight > 0 ->
            Weight;

        _ ->
            io:format("Invalid weight. Try again.~n"),
            get_valid_weight()
    end.

get_valid_destination() ->
    Input = string:lowercase(string:trim(io:get_line("Destination > "))),

    case Input of
        "" ->
            io:format("Invalid destination. Try again.~n"),
            get_valid_destination();

        _ ->
            case lists:all(fun is_letter/1, Input) of
                true ->
                    Input;

                false ->
                    io:format("Only letters allowed.~n"),
                    get_valid_destination()
            end
    end.

get_next_id([]) ->
    1;

get_next_id(Shipments) ->
    lists:max([S#shipment.id || S <- Shipments]) + 1.

add_to_end([], Elem) ->
    [Elem];

add_to_end([H | T], Elem) ->
    [H | add_to_end(T, Elem)].