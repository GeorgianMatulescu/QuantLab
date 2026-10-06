function state = updateMarketStateFromBar(state, barRow, barIndex)
state.clock.current_time = barRow.datetime_new_york(1);
state.clock.session_date = barRow.session_date_new_york(1);
state.clock.bar_index = barIndex;
state.price.open = barRow.open(1);
state.price.high = barRow.high(1);
state.price.low = barRow.low(1);
state.price.close = barRow.close(1);
state.price.volume = barRow.volume(1);
state.price.last_price = barRow.close(1);
state.session.bars_seen = state.session.bars_seen + 1;
state.session.session_high = max(state.session.session_high,barRow.high(1));
state.session.session_low = min(state.session.session_low,barRow.low(1));
state.session.session_close = barRow.close(1);
end
