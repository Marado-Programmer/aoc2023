let read_lines name : string list =
  let ic = open_in name in
  let try_read () =
    try Some (input_line ic) with End_of_file -> None in
  let rec loop acc = match try_read () with
    | Some s -> loop (s :: acc)
    | None -> close_in ic; List.rev acc in
  loop []
;;

let max_red = 12
let max_green = 13
let max_blue = 14

let parse_game game : ((int * (int * int * int) list), _) result =
  match String.split_on_char ':' game with
  | game :: subsets :: [] -> Ok ( 0, [] )
  | _ -> Error ()
;;

let process_game game : int =
  match parse_game game with
  | Ok (id, subsets) -> id
  | Error _ -> 0
;;

let part1 lines : int =
    let rec loop acc ls = match ls with
      | [] -> 0
      | x :: rest -> loop (acc + process_game x) rest in
    loop 0 lines
;;

let () =
  let lines = read_lines "../zig/test.in" in
  part1 lines |> string_of_int |> print_endline;
  (* part2 lines |> string_of_int |> print_endline *)
;;
