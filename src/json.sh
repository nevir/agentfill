# ============================================
# Tool detection
# ============================================

check_perl() {
	if ! command -v perl >/dev/null 2>&1; then
		panic 2 "Perl is required but not found. Please install perl."
	fi

	if ! perl -MJSON::PP -e 1 2>/dev/null; then
		panic 2 "Perl JSON::PP module is required but not found."
	fi
}

# ============================================
# JSON operations (Perl)
# ============================================

json_merge_deep() {
	local file="$1"
	local merge_json="$2"
	local temp_file="/tmp/json_merge_tmp_$$_$(date +%s)"

	cat "$file" | perl -MJSON::PP -0777 -e '
my $json = JSON::PP->new->utf8->relaxed->pretty->canonical;
my $base = $json->decode(do { local $/; <STDIN> });
my $merge = $json->decode(q{'"$merge_json"'});
my $base_json = $json->encode($base);

sub merge_recursive {
	my ($base, $merge) = @_;

	if (ref $merge eq "HASH") {
		$base = {} unless ref $base eq "HASH";
		for my $key (keys %$merge) {
			$base->{$key} = merge_recursive($base->{$key}, $merge->{$key});
		}
		return $base;
	} elsif (ref $merge eq "ARRAY") {
		$base = [] unless ref $base eq "ARRAY";
		# For arrays, merge unique elements
		my %seen;
		my @result;
		for my $item (@$base, @$merge) {
			my $key = ref $item ? $json->encode($item) : $item;
			push @result, $item unless $seen{$key}++;
		}
		return \@result;
	} else {
		return $merge;
	}
}

my $result = merge_recursive($base, $merge);
my $result_json = $json->encode($result);

print $result_json;
exit($base_json eq $result_json ? 0 : 1);
' > "$temp_file"

	local exit_code=$?
	mv "$temp_file" "$file"
	return $exit_code
}
