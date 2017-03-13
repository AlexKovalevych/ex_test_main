defmodule Gt.Fixtures.Project do
  alias Gt.Repo
  alias Gt.Project
  require Logger

  @projects [
    {
      "Loto 1",
      "lt1",
      "123",
      "http://loto1.com",
      true,
      "123"
    },
    {
      "Test1",
      "test1",
      "124",
      "http://socslots.com",
      true,
      "124"
    },
    {
      "Loto 2",
      "lt2",
      "130",
      "http://loto2.com/",
      true,
      "130"
    },
    {
      "Casino 1",
      "cs1",
      "125",
      "http://casino1.com/",
      true,
      "125"
    },
    {
      "Casino 2",
      "cs2",
      "143",
      "http://casino2.com/",
      true,
      "143"
    },
    {
      "Casino 3",
      "cs3",
      "135",
      "http://www.casino3.com/",
      true,
      "135"
    },
    {
      "Loto 3",
      "lt3",
      "136",
      "http://www.loto3.com/",
      true,
      "136"
    },
    {
      "Loto 4",
      "lt4",
      "137",
      "http://loto4.com/",
      true,
      "137"
    },
    {
      "Loto 5",
      "lt5",
      "138",
      "http://loto5.com/",
      true,
      "138"
    },
    {
      "Casino 4",
      "cs4",
      "2001",
      "http://www.casino4.net/",
      true,
      "2001"
    },
    {
      "Casino 5",
      "cs5",
      "141",
      "http://casino5.com/",
      true,
      "141"
    },
    {
      "Casino 6",
      "cs6",
      "150",
      "http://casino6.com/",
      true,
      "150"
    },
    {
      "Loto 6",
      "lt6",
      "2002",
      "http://www.32slots.com/",
      true,
      "2002",
        true
    },
    {
      "Loto 7",
      "lt7",
      "151",
      "http://loto7.com/",
      true,
      "151"
    },
    {
      "Loto 8",
      "lt8",
      "152",
      "http://loto8.com/",
      true,
      "152"
    },
    {
      "Casino 7",
      "cs7",
      "157",
      "http://casino7.com/",
      true,
      "157"
    },
    {
      "Test 2",
      "test2",
      "154",
      "http://test2.com/",
      true,
      "154"
    },
    {
      "Casino 8",
      "cs8",
      "2003",
      "http://casino8.com/",
      true,
      "2003"
    },
    {
      "Casino 9",
      "cs9",
      "159",
      "http://www.casino9.com/",
      true,
      "159"
    },
    {
      "Test 3",
      "test3",
      "201",
      "http://test3.com",
      true,
      "201"
    },
    {
      "Test 4",
      "test4",
      "1021",
      "http://test4.com/",
      true,
      "1021"
    },
    {
      "Test 5",
      "test5",
      "161",
      "http://test5.com/",
      true,
      "161"
    },
    {
      "Demo project",
      "DEMO",
      "202",
      "http://demo.com",
      true,
      "202"
    },
    {
      "Loto 9",
      "lt9",
      "163",
      "http://loto9.com",
      true,
      "163"
    },
    {
      "DemoProject",
      "demoproject",
      "111",
      "http://demoproject.com/",
      false,
      "111"
    }
  ]

  def run do
    @projects
    |> Enum.map(&get_project/1)
    |> Enum.map(&Repo.insert!/1)
  end

  def get_project({title, prefix, item_id, url, enabled, external_id}) do
    %Project{
      title: title,
      prefix: prefix,
      item_id: item_id,
      url: url,
      enabled: enabled,
      external_id: external_id
    }
  end

  def get_project({title, prefix, item_id, url, enabled, external_id, isPoker}) do
    %Project{
      title: title,
      prefix: prefix,
      item_id: item_id,
      url: url,
      enabled: enabled,
      external_id: external_id,
      is_poker: isPoker
    }
  end

end

