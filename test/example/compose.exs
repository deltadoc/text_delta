delta_a =
  TextDelta.new()
  |> TextDelta.insert(
    "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book.",
    %{"bold" => true}
  )
  |> TextDelta.retain(3)
  |> TextDelta.delete(2)
  |> TextDelta.insert(
    "Contrary to popular belief, Lorem Ipsum is not simply random text. It has roots in a piece of classical Latin literature from 45 BC, making it over 2000 years old."
  )

delta_b =
  TextDelta.new()
  |> TextDelta.insert(
    "There are many variations of passages of Lorem Ipsum available, "
  )
  |> TextDelta.delete(4)
  |> TextDelta.insert(
    "All the Lorem Ipsum generators on the Internet tend to repeat predefined chunks",
    %{"font" => "Arial"}
  )

TextDelta.compose(delta_a, delta_b)
