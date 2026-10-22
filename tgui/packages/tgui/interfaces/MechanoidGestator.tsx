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

type CoreData = {
  name: string;
  tier: string;
  caste: string;
  bandwidth: number;
  need_metal: number;
  need_plasteel: number;
  result: string;
  time: number;
  variants: Variant[];
};

type Variant = {
  index: number;
  name: string;
  bandwidth: number;
  desc: string;
  selected: boolean;
};

type DeadMechanoid = {
  name: string;
  ref: string;
  bandwidth: number;
  need_metal: number;
};

type GestatorData = {
  metal: number;
  plasteel: number;
  max_sheets: number;
  bandwidth_used: number;
  bandwidth_max: number;
  busy: boolean;
  resurrecting: boolean;
  progress: number;
  time_left: number;
  core: CoreData | null;
  dead_mechanoids: DeadMechanoid[];
};

const TIER_COLORS: Record<string, string> = {
  basic: 'pink',
  standard: 'yellow',
  high: 'red',
};

export const MechanoidGestator = (props) => {
  const { act, data } = useBackend<GestatorData>();
  const {
    metal,
    plasteel,
    max_sheets,
    bandwidth_used,
    bandwidth_max,
    busy,
    resurrecting,
    progress,
    time_left,
    core,
    dead_mechanoids,
  } = data;

  const enoughMetal = core ? metal >= core.need_metal : false;
  const enoughPlasteel = core ? plasteel >= core.need_plasteel : false;
  const enoughBandwidth = core
    ? bandwidth_used + core.bandwidth <= bandwidth_max
    : false;
  const canStart = !!core && !busy && enoughMetal && enoughPlasteel && enoughBandwidth;

  return (
    <Window width={460} height={680} theme="ntos">
      <Window.Content scrollable>
        <Stack vertical>
          <Stack.Item>
            <Section title="Mechanoid gestator">
              {busy ? (
                <ProgressBar
                  value={progress}
                  minValue={0}
                  maxValue={100}
                  color="good"
                  ranges={{ good: [0, 100] }}
                >
                  {resurrecting ? 'Rebuilding' : 'Growing'} ({time_left}s left)
                </ProgressBar>
              ) : (
                <NoticeBox info>Idle</NoticeBox>
              )}
            </Section>
          </Stack.Item>

          <Stack.Item>
            <Section title="Ship bandwidth">
              <ProgressBar
                value={bandwidth_used}
                minValue={0}
                maxValue={bandwidth_max}
                ranges={{
                  good: [0, bandwidth_max * 0.5],
                  average: [bandwidth_max * 0.5, bandwidth_max * 0.85],
                  bad: [bandwidth_max * 0.85, bandwidth_max],
                }}
              >
                {bandwidth_used} / {bandwidth_max}
              </ProgressBar>
            </Section>
          </Stack.Item>

          <Stack.Item>
            <Section
              title="Materials"
              buttons={
                <Button
                  icon="eject"
                  disabled={busy || (metal === 0 && plasteel === 0)}
                  onClick={() => act('eject_materials')}
                >
                  Eject
                </Button>
              }
            >
              <LabeledList>
                <LabeledList.Item label="Metal">
                  <ProgressBar
                    value={metal}
                    minValue={0}
                    maxValue={max_sheets}
                    color="average"
                  >
                    {metal} / {max_sheets}
                  </ProgressBar>
                </LabeledList.Item>
                <LabeledList.Item label="Plasteel">
                  <ProgressBar
                    value={plasteel}
                    minValue={0}
                    maxValue={max_sheets}
                    color="blue"
                  >
                    {plasteel} / {max_sheets}
                  </ProgressBar>
                </LabeledList.Item>
              </LabeledList>
              <Box color="label" mt={1}>
                Click the gestator with sheets to load them.
              </Box>
            </Section>
          </Stack.Item>

          <Stack.Item>
            <Section
              title="Subcore"
              buttons={
                <Button
                  icon="eject"
                  disabled={busy || !core}
                  onClick={() => act('eject_core')}
                >
                  Eject
                </Button>
              }
            >
              {core ? (
                <>
                  <LabeledList>
                    <LabeledList.Item label="Type">
                      <Box
                        as="span"
                        bold
                        color={TIER_COLORS[core.tier] || 'white'}
                      >
                        {core.tier} subcore
                      </Box>{' '}
                      ({core.caste})
                    </LabeledList.Item>
                    <LabeledList.Item label="Grows">{core.result}</LabeledList.Item>
                    <LabeledList.Item label="Bandwidth">
                      <Box color={enoughBandwidth ? 'good' : 'bad'}>
                        {core.bandwidth}
                      </Box>
                    </LabeledList.Item>
                    <LabeledList.Item label="Metal">
                      <Box color={enoughMetal ? 'good' : 'bad'}>
                        {core.need_metal}
                      </Box>
                    </LabeledList.Item>
                    <LabeledList.Item label="Plasteel">
                      <Box color={enoughPlasteel ? 'good' : 'bad'}>
                        {core.need_plasteel}
                      </Box>
                    </LabeledList.Item>
                    <LabeledList.Item label="Time">{core.time}s</LabeledList.Item>
                  </LabeledList>
                  <Box bold mt={1} mb={1}>
                    Choose a mechanoid
                  </Box>
                  {core.variants.map((v) => (
                    <Button
                      key={v.index}
                      fluid
                      mb={1}
                      selected={v.selected}
                      disabled={busy}
                      tooltip={v.desc}
                      onClick={() => act('set_variant', { index: v.index })}
                    >
                      {v.name} ({v.bandwidth} bandwidth)
                    </Button>
                  ))}
                  <Box color="label" mb={1}>
                    {core.variants.find((v) => v.selected)?.desc}
                  </Box>
                  <Button
                    mt={1}
                    fluid
                    icon="play"
                    color="good"
                    disabled={!canStart}
                    onClick={() => act('start')}
                  >
                    Start gestation
                  </Button>
                </>
              ) : (
                <NoticeBox>
                  Empty. Make a subcore in the subnuclear encoder and load it.
                </NoticeBox>
              )}
            </Section>
          </Stack.Item>

          <Stack.Item>
            <Section title="Resurrection">
              {dead_mechanoids.length === 0 ? (
                <Box color="label">
                  No dead mechanoids next to the gestator.
                </Box>
              ) : (
                dead_mechanoids.map((mech) => (
                  <Stack key={mech.ref} align="center" mb={1}>
                    <Stack.Item grow>
                      {mech.name} (bandwidth {mech.bandwidth}, {mech.need_metal}{' '}
                      metal)
                    </Stack.Item>
                    <Stack.Item>
                      <Button
                        icon="heart"
                        color="good"
                        disabled={busy || metal < mech.need_metal}
                        onClick={() => act('resurrect', { ref: mech.ref })}
                      >
                        Resurrect
                      </Button>
                    </Stack.Item>
                  </Stack>
                ))
              )}
            </Section>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
