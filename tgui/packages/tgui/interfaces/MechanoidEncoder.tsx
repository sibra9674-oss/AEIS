import {
  Box,
  Button,
  LabeledList,
  NoticeBox,
  ProgressBar,
  Section,
  Stack,
} from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type Corpse = {
  name: string;
  caste: string;
  ref: string;
  subcore: string;
  bandwidth: number;
};

type EncoderData = {
  processing: boolean;
  progress: number;
  time_left: number;
  processing_name: string | null;
  corpses: Corpse[];
};

const TIER_COLORS: Record<string, string> = {
  basic: 'pink',
  standard: 'yellow',
  high: 'red',
};

export const MechanoidEncoder = (props) => {
  const { act, data } = useBackend<EncoderData>();
  const { processing, progress, time_left, processing_name, corpses } = data;

  return (
    <Window width={430} height={420} theme="ntos">
      <Window.Content scrollable>
        <Stack vertical fill>
          <Stack.Item>
            <Section title="Subnuclear encoder">
              <Box color="label" mb={1}>
                Burns a dead xenomorph down to its brain and encodes it into a
                subcore. The body is destroyed.
              </Box>
              {processing ? (
                <>
                  <ProgressBar
                    value={progress}
                    minValue={0}
                    maxValue={100}
                    color="good"
                    ranges={{ good: [0, 100] }}
                  >
                    Encoding {processing_name} ({time_left}s)
                  </ProgressBar>
                </>
              ) : (
                <NoticeBox info>Ready</NoticeBox>
              )}
            </Section>
          </Stack.Item>
          <Stack.Item grow>
            <Section fill title="Corpses in range">
              {corpses.length === 0 ? (
                <NoticeBox>
                  No suitable corpse next to the encoder. Only dead tier 1-3
                  xenomorphs work.
                </NoticeBox>
              ) : (
                corpses.map((corpse) => (
                  <Section
                    key={corpse.ref}
                    title={corpse.name}
                    buttons={
                      <Button
                        icon="bolt"
                        color="good"
                        disabled={processing}
                        onClick={() => act('encode', { ref: corpse.ref })}
                      >
                        Encode
                      </Button>
                    }
                  >
                    <LabeledList>
                      <LabeledList.Item label="Caste">
                        {corpse.caste}
                      </LabeledList.Item>
                      <LabeledList.Item label="Result">
                        <Box
                          as="span"
                          bold
                          color={TIER_COLORS[corpse.subcore] || 'white'}
                        >
                          {corpse.subcore} subcore
                        </Box>
                      </LabeledList.Item>
                      <LabeledList.Item label="Bandwidth">
                        {corpse.bandwidth}
                      </LabeledList.Item>
                    </LabeledList>
                  </Section>
                ))
              )}
            </Section>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
