defmodule PlumMail.Web.RouterTest do
  use ExUnit.Case

  for {name, 0} <- :plum_mail@web@router_test.module_info(:exports) do
    if String.ends_with?(Atom.to_string(name), "_test") do
      test name do
        :plum_mail@web@router_test.unquote(name)()
      end
    end
  end
end
