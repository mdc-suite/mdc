/*
 * Copyright (c) 2010, IRISA
 * Copyright (c) 2011, IETR/INSA Rennes
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 
 *   * Redistributions of source code must retain the above copyright notice,
 *     this list of conditions and the following disclaimer.
 *   * Redistributions in binary form must reproduce the above copyright notice,
 *     this list of conditions and the following disclaimer in the documentation
 *     and/or other materials provided with the distribution.
 *   * Neither the name of the IRISA nor the names of its
 *     contributors may be used to endorse or promote products derived from this
 *     software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 * WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */
package net.sf.orcc.ui.launching.impl;

import net.sf.orcc.plugins.Option;
import net.sf.orcc.ui.launching.tabs.OrccAbstractSettingsTab;

import org.eclipse.core.runtime.CoreException;
import org.eclipse.debug.core.ILaunchConfiguration;
import org.eclipse.debug.core.ILaunchConfigurationWorkingCopy;
import org.eclipse.swt.SWT;
import org.eclipse.swt.events.ModifyEvent;
import org.eclipse.swt.events.ModifyListener;
import org.eclipse.swt.graphics.Font;
import org.eclipse.swt.layout.GridData;
import org.eclipse.swt.layout.GridLayout;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Label;
import org.eclipse.swt.widgets.Text;

/**
 * This class defines a text box input.
 * 
 * @author Herve Yviquel
 * @author Matthieu Wipliez
 */
public class TextBoxOptionWidget extends AbstractOptionWidget implements
		ModifyListener {

	protected Text text;

	protected String value;

	public TextBoxOptionWidget(OrccAbstractSettingsTab tab, Option option,
			Composite parent) {
		super(tab, option, parent);
		this.value = "";
	}

	@Override
	protected Composite createControl(Composite parent) {
		Composite composite = new Composite(parent, SWT.NONE);
		composite.setLayout(new GridLayout(2, false));

		GridData data = new GridData(SWT.FILL, SWT.TOP, true, false);
		data.horizontalSpan = 2;
		composite.setLayoutData(data);

		Font font = parent.getFont();

		Label lbl = new Label(composite, SWT.NONE);
		lbl.setFont(font);
		lbl.setText(option.getName() + ":");
		lbl.setToolTipText(option.getDescription());

		data = new GridData(SWT.LEFT, SWT.CENTER, false, false);
		lbl.setLayoutData(data);

		text = new Text(composite, SWT.BORDER | SWT.SINGLE);
		text.setFont(font);
		data = new GridData(SWT.FILL, SWT.CENTER, true, false);
		text.setLayoutData(data);
		text.addModifyListener(this);
		
		return composite;
	}

	@Override
	public void initializeFrom(ILaunchConfiguration configuration)
			throws CoreException {
		updateLaunchConfiguration = false;
		text.setText(configuration.getAttribute(option.getIdentifier(),
				option.getDefaultValue()));
		updateLaunchConfiguration = true;
	}

	@Override
	public boolean isValid(ILaunchConfiguration launchConfig) {
		if (value.isEmpty()) {
			launchConfigurationTab.setErrorMessage("The \"" + option.getName()
					+ "\" field is empty");
			return false;
		}

		return true;
	}

	@Override
	public void performApply(ILaunchConfigurationWorkingCopy configuration) {
		configuration.setAttribute(option.getIdentifier(), value);
	}

	@Override
	public void modifyText(ModifyEvent e) {
		value = text.getText();
		if (updateLaunchConfiguration) {
			launchConfigurationTab.updateLaunchConfigurationDialog();
		}
	}

}
