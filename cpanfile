requires "Clone" => "0";
requires "Const::Fast" => "0";
requires "Hash::Merge" => "0";
requires "List::AllUtils" => "0";
requires "List::MoreUtils" => "0";
requires "Moo" => "0";
requires "Moose" => "0";
requires "Moose::Exporter" => "0";
requires "MooseX::MungeHas" => "0";
requires "Scalar::Util" => "0";
requires "Type::Tiny" => "0";
requires "Types::Standard" => "0";
requires "experimental" => "0";
requires "overload" => "0";
requires "strict" => "0";
requires "warnings" => "0";

on 'test' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "Test::Exception" => "0";
  requires "Test::More" => "0";
  requires "perl" => "v5.20.0";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "2.120900";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
};

on 'develop' => sub {
  requires "Test::More" => "0";
  requires "Test::PAUSE::Permissions" => "0";
};
