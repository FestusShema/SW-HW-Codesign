            case scheduler_state is

              when SCHEDULE_IDLE =>
                if writer_is_active = '1' then
                  next_scheduler_state <= SCHEDULE_WRITER;
                  mst_cmd_sm_state <= CMD_PREPARE;
                elsif reader_is_active = '1' then
                  next_scheduler_state <= SCHEDULE_READER;
                  mst_cmd_sm_state <= CMD_PREPARE;
                end if;

              when SCHEDULE_READER =>
                if writer_is_active = '1' then
                  next_scheduler_state <= SCHEDULE_WRITER;
                  mst_cmd_sm_state <= CMD_PREPARE;
                elsif reader_is_active = '1' then
                  next_scheduler_state <= SCHEDULE_READER;
                  mst_cmd_sm_state <= CMD_PREPARE;
                else
                  next_scheduler_state <= SCHEDULE_IDLE;
                end if;

              when SCHEDULE_WRITER =>
                if reader_is_active = '1' then
                  next_scheduler_state <= SCHEDULE_READER;
                  mst_cmd_sm_state <= CMD_PREPARE;
                elsif writer_is_active = '1' then
                  next_scheduler_state <= SCHEDULE_WRITER;
                  mst_cmd_sm_state <= CMD_PREPARE;
                else
                  next_scheduler_state <= SCHEDULE_IDLE;
                end if;

              when others =>
                next_scheduler_state <= SCHEDULE_IDLE;

            end case;

            case next_scheduler_state is  -- TODO: register end address
              when SCHEDULE_READER =>
                remaining_words := (reader_end_address_reg - current_reader_address) / 8;
              when SCHEDULE_WRITER =>
                remaining_words := (writer_end_address_reg - current_writer_address) / 8;
              when others =>
                null;
            end case;

            scheduler_state <= next_scheduler_state;

            if conv_integer(remaining_words) >= BURST_LENGTH then
              beats := BURST_LENGTH;
            else
              beats := conv_integer(remaining_words);
            end if;
            
            if beats > 1 then
              mst_cntl_burst <= '1';
            else
              mst_cntl_burst <= '0';
            end if;
            
            mst_xfer_length <= conv_std_logic_vector(beats * (C_MST_DWIDTH/8), 12);
              
            if conv_integer(remaining_words) = 0 then
              -- stay in idle state
              case scheduler_state is
                when SCHEDULE_READER =>
                  status_reader_done <= '1';
                when SCHEDULE_WRITER =>
                  status_writer_done <= '1';
                when others =>
                  null;
              end case;
            end if;

          when CMD_PREPARE =>

            case scheduler_state is
              when SCHEDULE_READER =>
                if conv_integer(reader_fifo_wr_count) < (FIFO_SIZE-beats) then
                  -- start reader FSM
                  mst_cmd_sm_start_rd_llink <= '1';
                  mst_ip2bus_addr <= current_reader_address;
                  mst_cmd_sm_state <= CMD_RUN;
                end if;
              when SCHEDULE_WRITER =>
                if conv_integer(writer_fifo_rd_count) >= beats then
                  -- start writer FSM
                  mst_cmd_sm_start_wr_llink <= '1';
                  mst_ip2bus_addr <= current_writer_address;
                  mst_cmd_sm_state <= CMD_RUN;
                end if;
              when others =>
                null;
            end case;

----              if conv_integer(writer_remaining_words) = 0 then
----              if (conv_integer(writer_remaining_words) = 0) or (conv_integer(writer_remaining_words) < 8) then
--              if (conv_integer(writer_remaining_words) = 0) or (writer_remaining_words(0) = '1') then
--                  status_writer_done <= '1';
--              else
----                if conv_integer(writer_fifo_rd_count) >= writer_beats then
--                if conv_integer(writer_fifo_rd_count) >= (writer_beats-2) then
--                   -- start writer FSM
--                  mst_cmd_sm_start_wr_llink <= '1';
--                  mst_ip2bus_addr <= current_writer_address;
--                  mst_cmd_sm_state <= CMD_RUN;
--                end if;
--              end if;
--            end if;
