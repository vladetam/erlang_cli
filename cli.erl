-module(cli).
-export([start/0]).

start() ->
    Shipments = seed(),
    loop(Shipments).

seed() ->
[
 {shipment,1,125,"belgrade",pending},
 {shipment,2,70,"athens",in_transit},
 {shipment,3,230,"podgorica",pending},
 {shipment,4,75,"belgrade",delivered},
 {shipment,5,95,"skopje",delivered},
 {shipment,6,200,"zagreb",pending},
 {shipment,7,65,"athens",delivered},
 {shipment,8,55,"podgorica",in_transit},
 {shipment,9,130,"zagreb",delivered},
 {shipment,10,180,"belgrade",pending}
 %%{shipment,11,0,"podgorica",pending} % invalid weight
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

handle_input("5",_) ->
    io:format("Exiting Terminal...~n"),
    ok;

handle_input(_, Shipments) ->
     io:format("Invalid selection.~n"),
            loop(Shipments).


menu() ->
    io:format("~n1. View All | 2. Filter | 3. Statistics | 4. Dispatch | 5. Exit~n").

view_all([]) ->
    ok;

view_all([Head | Tail]) ->
    print_shipment(Head),
    view_all(Tail).

print_shipment({shipment,ID,Weight,Destination,Status}) ->
    io:format("ID: ~p | Weight: ~p | Dest: ~s | Status: ~p~n",[ID,Weight,Destination,Status]).

filter(Shipments) ->
    Input = io:get_line("Destination > "),
    TrimInput = string:trim(Input),

    case TrimInput of
        "" ->
            io:format("Invalid input. Please enter a destination.~n");

        _ ->
            case string:to_integer(TrimInput) of
                {error, _} ->
                    run_filter(Shipments, TrimInput);
                {_, _} ->
                    io:format("Invalid input. Destination must contain only letters.~n")
            end
    end.

run_filter(Shipments, Dest) ->
    Filtered =
        lists:filter(
            fun({shipment,_,_,Destination,_}) ->
                Destination =:= Dest
            end,
            Shipments
        ),

    case Filtered of
        [] ->
            io:format("No shipments found.~n");
        _ ->
            view_all(Filtered)
    end.

stats(Shipments) ->
    try
        {Weight, Delivered} =
            lists:foldl(
                fun({shipment,_,Wght,_,Status}, {AccWeight,AccDelivered}) ->

                    case Wght =< 0 of
                        true -> throw(invalid_weight);
                        false -> ok
                    end,

                    case Status of
                        pending ->
                            {AccWeight + Wght, AccDelivered};

                        delivered ->
                            {AccWeight, AccDelivered + 1};

                        _ ->
                            {AccWeight, AccDelivered}
                    end

                end,
                {0,0},
                Shipments
            ),

        io:format(
            "Statistics: Total Pending Weight: ~pkg | Total Delivered: ~p~n",
            [Weight, Delivered])

    catch
        invalid_weight ->
            io:format("Error: Invalid shipment weight~n")
    end.

dispatch(Shipments) ->
    lists:map(
        fun({shipment,ID,Weight,Destination,pending}) ->
                {shipment,ID,Weight,Destination,in_transit};

           (Shipment) ->
                Shipment
        end,
    Shipments).